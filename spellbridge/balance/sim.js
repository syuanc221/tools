// headless balance probes on the real engine: unit-vs-unit duels and solo tower pushes
window.SIM={
  reset(){newGame({});G.ents=[];G.proj=[];G.spells=[];G.running=true;G.pvp=true;G.lv1={};VIEW='sim'},
  spawn(k,team,x,y){const c=CARDS[k];for(const[ox,oy]of offsFor(c.count))G.ents.push(makeUnit(k,team,x+ox,y+(team?-oy:oy),1))},
  side(t){return G.ents.filter(e=>e.team===t&&!e.dead&&e.hp>0)},
  hpOf(t){return this.side(t).reduce((s,e)=>s+e.hp,0)},
  duel(a,b){
    this.reset();this.spawn(a,0,180,520);this.spawn(b,1,180,400);
    const h0=[this.hpOf(0),this.hpOf(1)];
    for(let i=0;i<30*40;i++){update(1/30);if(!this.side(0).length||!this.side(1).length)break}
    const A=this.side(0).length,B=this.side(1).length;
    if(A&&!B)return 1;if(B&&!A)return 0;if(!A&&!B)return .5;
    const fa=this.hpOf(0)/h0[0],fb=this.hpOf(1)/h0[1];return Math.abs(fa-fb)<.05?.5:fa>fb?1:0;
  },
  push(a){ // damage to an undefended princess tower in 30s
    this.reset();const tw=tower(1,70,130,false);tw.hp=tw.maxHp=1e6;G.ents.push(tw);this.spawn(a,0,70,430);
    for(let i=0;i<30*25;i++)update(1/30);
    return Math.round(1e6-tw.hp);
  },
  run(){
    const keys=Object.keys(CARDS).filter(k=>CARDS[k].type!=='spell'),out={};
    for(const a of keys){let w=0,n=0;for(const b of keys){if(a===b)continue;w+=this.duel(a,b);n++}out[a]={win:w/n,push:this.push(a),cost:CARDS[a].cost,rar:CARDS[a].rar,type:CARDS[a].type,bo:!!CARDS[a].s.buildingsOnly}}
    return out;
  }
};
