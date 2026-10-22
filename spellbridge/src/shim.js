// Standalone backend: maps the game's claude.use('db' | 'user' | 'room') calls onto Supabase (auth, a single docs table, realtime channels).
(function(){
  const URL=window.SB_URL,KEY=window.SB_KEY;
  if(!URL||!KEY||!window.supabase){window.AUTH={configured:false,user:null};return}
  const sb=window.supabase.createClient(URL,KEY);
  let user=null;
  // events before getSession settles (INITIAL_SESSION, SIGNED_IN from the OAuth redirect) only record the user; reloading on them looped forever
  let settled=false;
  const ready=sb.auth.getSession().then(r=>{user=r.data.session?r.data.session.user:null}).catch(()=>{}).finally(()=>{settled=true});
  sb.auth.onAuthStateChange((ev,ses)=>{const nu=ses?ses.user:null;if(ev==='INITIAL_SESSION'||!settled){if(!settled)user=nu;return}
    if((nu&&nu.id)!==(user&&user.id)){user=nu;if(window.__booted)location.reload()}});
  window.AUTH={configured:true,ready,get user(){return user},
    signIn:p=>sb.auth.signInWithOAuth({provider:p,options:{redirectTo:location.origin+location.pathname}}),
    signOut:()=>sb.auth.signOut()};
  const fail=e=>({code:e&&(e.code==='42501'||/row-level security/i.test(e.message||''))?'invalid_argument':'unavailable',message:(e&&e.message)||'error'});
  const split=p=>{const i=p.lastIndexOf('/');return[p.slice(0,i),p.slice(i+1)]};
  const snap=(id,row)=>({id,exists:!!row,data:()=>row?row.data:undefined,metadata:{fromCache:false,hasPendingWrites:false}});
  function docRef(path){
    const[coll,id]=split(path);
    return{id,path,
      async get(){const{data,error}=await sb.from('docs').select('data').eq('path',path).maybeSingle();if(error)throw fail(error);return snap(id,data)},
      async set(d){if(!user)throw{code:'invalid_argument',message:'signed out'};const{error}=await sb.from('docs').upsert({path,coll,id,owner:user.id,data:d,updated_at:new Date().toISOString()});if(error)throw fail(error)},
      async update(d){const cur=await this.get();if(!cur.exists)throw{code:'invalid_argument',message:'missing'};await this.set(Object.assign({},cur.data(),d))},
      async delete(){const{error}=await sb.from('docs').delete().eq('path',path);if(error)throw fail(error)},
      collection(sub){return query(path+'/'+sub,[],null,null)}};
  }
  function query(coll,wh,ord,lim){
    const run=async()=>{let r=sb.from('docs').select('id,data').eq('coll',coll);for(const[f,op,v]of wh)if(op==='==')r=r.eq('data->>'+f,String(v));if(ord)r=r.order('data->'+ord[0],{ascending:ord[1]!=='desc',nullsFirst:false});r=r.limit(lim||1000);const{data,error}=await r;if(error)throw fail(error);
      const docs=data.map(x=>snap(x.id,x));return{docs,size:docs.length,empty:!docs.length,docChanges:()=>[],metadata:{fromCache:false,hasPendingWrites:false}}};
    return{path:coll,
      where:(f,op,v)=>query(coll,[...wh,[f,op,v]],ord,lim),orderBy:(f,d)=>query(coll,wh,[f,d||'asc'],lim),limit:n=>query(coll,wh,ord,n),
      doc:id=>docRef(coll+'/'+(id||crypto.randomUUID())),
      async add(d){const r=docRef(coll+'/'+crypto.randomUUID());await r.set(d);return r},
      get:run,
      onSnapshot(next,err){
        let alive=true,t=null;
        const go=()=>run().then(s=>{if(alive)next(s)}).catch(()=>{});
        const soon=()=>{clearTimeout(t);t=setTimeout(go,150)};
        go();
        const ch=sb.channel('docs-'+Math.random().toString(36).slice(2))
          .on('postgres_changes',{event:'*',schema:'public',table:'docs',filter:'coll=eq.'+coll},soon)
          .on('postgres_changes',{event:'DELETE',schema:'public',table:'docs'},p=>{const o=p.old||{};if(!o.path||o.path.startsWith(coll+'/'))soon()})
          .subscribe();
        const poll=setInterval(go,30000);
        return()=>{alive=false;clearInterval(poll);clearTimeout(t);sb.removeChannel(ch)};
      }};
  }
  const db={doc:docRef,collection:c=>query(c,[],null,null)};
  const userNS={id:async()=>{await ready;return user?user.id:null},can:async()=>!!user,isOwner:async()=>false,canEdit:async()=>false,
    me:async()=>({id:user?user.id:null,name:'',avatarUrl:'',color:'#3b82f6',email:user?user.email:null,isOwner:false,canEdit:false}),profiles:async ids=>Object.fromEntries([].concat(ids).map(i=>[i,{id:i,name:'',avatarUrl:'',color:'#3b82f6',email:null,isMe:!!user&&i===user.id,guest:false}]))};
  // Live rooms: Supabase presence for who is here; broadcast for events and for the fast-changing 'st' field (match snapshots).
  const lobby={async join(name){
    const key='p'+Math.random().toString(36).slice(2,10);
    const ch=sb.channel('room-'+name,{config:{presence:{key},broadcast:{self:false}}});
    const handlers={},peerH=[],stOf={};let mine={},peersArr=[];
    const build=()=>{const s=ch.presenceState(),arr=[];for(const k in s){const p=(s[k]&&s[k][0])||{};const pr=Object.assign({},p.p||{});if(k!==key&&stOf[k]!==undefined)pr.st=stOf[k];arr.push({peer:k,by:null,isMe:k===key,sameTab:k===key,kind:'viewer',guest:false,presence:pr,updatedAt:Date.now()})}return arr};
    const emitPeers=()=>{const old=new Map(peersArr.map(p=>[p.peer,p]));peersArr=build();const now=new Set(peersArr.map(p=>p.peer));
      const ch2={peers:peersArr,joined:peersArr.filter(p=>!old.has(p.peer)),left:[...old.values()].filter(p=>!now.has(p.peer)),updated:peersArr.filter(p=>old.has(p.peer))};peerH.forEach(h=>{try{h(ch2)}catch(e){}})};
    ch.on('presence',{event:'sync'},emitPeers);
    ch.on('broadcast',{event:'msg'},({payload})=>{const m=payload||{};(handlers[m.topic]||[]).forEach(h=>{try{h({topic:m.topic,data:m.data,peer:m.peer,by:null,isMe:false,sameTab:false,kind:'viewer',guest:false})}catch(e){}})});
    ch.on('broadcast',{event:'st'},({payload})=>{const m=payload||{};if(!m.peer)return;stOf[m.peer]=m.st;emitPeers()});
    await new Promise((res,rej)=>{const to=setTimeout(()=>rej({code:'upstream_error',message:'timeout'}),10000);ch.subscribe(s=>{if(s==='SUBSCRIBED'){clearTimeout(to);res()}else if(s==='CHANNEL_ERROR'||s==='TIMED_OUT'){clearTimeout(to);rej({code:'upstream_error',message:s})}})});
    let tt=null;
    return{name,
      emit:async(topic,data)=>{await ch.send({type:'broadcast',event:'msg',payload:{topic,data,peer:key}})},
      on:(t,h)=>{(handlers[t]=handlers[t]||[]).push(h);return()=>{}},
      presence:async patch=>{
        if('st' in patch){const st=patch.st;patch=Object.assign({},patch);delete patch.st;if(st!=null)ch.send({type:'broadcast',event:'st',payload:{peer:key,st}}).catch(()=>{});if(!Object.keys(patch).length)return}
        mine=Object.assign({},mine,patch);for(const k in mine)if(mine[k]===null)delete mine[k];
        clearTimeout(tt);tt=setTimeout(()=>ch.track({p:mine}).catch(()=>{}),60);
      },
      peers:()=>peersArr,
      onPeers:h=>{peerH.push(h);setTimeout(()=>h({peers:peersArr,joined:peersArr,left:[],updated:[]}),0);return()=>{}},
      connected:()=>true,
      leave:async()=>{try{await ch.untrack()}catch(e){}sb.removeChannel(ch)}};
  }};
  // db is handed out signed-out too so the public leaderboards load; writes still require a user (docRef.set)
  window.claude={use:async n=>{await ready;if(n==='db')return db;if(n==='user')return userNS;if(n==='room')return lobby;return null}};
})();
