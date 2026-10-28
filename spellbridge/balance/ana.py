import json,sys
d=json.load(open(sys.argv[1]))
def fit(xs,ys):
    n=len(xs);mx=sum(xs)/n;my=sum(ys)/n;b=sum((x-mx)*(y-my) for x,y in zip(xs,ys))/sum((x-mx)**2 for x in xs);return my-b*mx,b
ks=list(d)
a,b=fit([d[k]['cost'] for k in ks],[d[k]['win'] for k in ks])
pk=[k for k in ks if d[k]['type']=='troop']
ppc=sum(d[k]['push'] for k in pk)/sum(d[k]['cost'] for k in pk);a2,b2=0,ppc
rows=[]
for k in ks:
    v=d[k];r=v['win']-(a+b*v['cost'])
    pr=(v['push']-(a2+b2*v['cost']))/(a2+b2*v['cost']) if v['type']=='troop' else 0
    rows.append((r+.25*pr,k,v,r,pr))
rows.sort()
print('win ~ %.2f + %.3f*cost; push ~ %.0f + %.0f*cost'%(a,b,a2,b2))
for s,k,v,r,pr in rows:print('%-14s c%d %-9s win %.2f res %+.2f push %5d (%+.0f%%) score %+.2f'%(k,v['cost'],v['rar'][:4],v['win'],r,v['push'],pr*100,s))
sd=(sum(x[0]**2 for x in rows)/len(rows))**.5;print('spread',round(sd,3))
