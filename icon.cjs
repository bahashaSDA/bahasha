const Jimp = require('jimp');
const src = 'C:/Users/HomePC/Documents/bahasha/ChatGPT Image Aug 25, 2026, 12_05_41 AM.png';
const outDir = 'C:/Users/HomePC/Documents/bahasha/bahasha-mobile/assets/icon';
(async () => {
  const img = await Jimp.read(src);
  const b = img.bitmap, w = b.width, h = b.height, d = b.data;
  // border flood-fill white -> transparent
  const isWhite = (i) => { const r=d[i],g=d[i+1],bl=d[i+2]; const mn=Math.min(r,g,bl),mx=Math.max(r,g,bl); return mn>=234 && (mx-mn)<=16; };
  const vis = new Uint8Array(w*h); const st = [];
  for (let x=0;x<w;x++){ st.push(x,(h-1)*w+x); } for (let y=0;y<h;y++){ st.push(y*w,y*w+w-1); }
  while (st.length){ const p=st.pop(); if(vis[p])continue; vis[p]=1; const i=p*4; if(!isWhite(i))continue; d[i+3]=0; const x=p%w,y=(p-x)/w; if(x+1<w)st.push(p+1); if(x-1>=0)st.push(p-1); if(y+1<h)st.push(p+w); if(y-1>=0)st.push(p-w); }
  // defringe one ring
  for (let y=0;y<h;y++) for (let x=0;x<w;x++){ const p=y*w+x,i=p*4; if(d[i+3]===0)continue; let nb=false; if(x+1<w&&d[(p+1)*4+3]===0)nb=true; else if(x-1>=0&&d[(p-1)*4+3]===0)nb=true; else if(y+1<h&&d[(p+w)*4+3]===0)nb=true; else if(y-1>=0&&d[(p-w)*4+3]===0)nb=true; if(nb){ const mn=Math.min(d[i],d[i+1],d[i+2]); if(mn>=210) d[i+3]=Math.min(d[i+3],120); } }
  // bounding box of opaque pixels
  let minx=w,miny=h,maxx=0,maxy=0;
  for (let y=0;y<h;y++) for (let x=0;x<w;x++){ if(d[(y*w+x)*4+3]>10){ if(x<minx)minx=x; if(x>maxx)maxx=x; if(y<miny)miny=y; if(y>maxy)maxy=y; } }
  const cropped = img.clone().crop(minx,miny,maxx-minx+1,maxy-miny+1);

  // adaptive foreground: logo at ~72% of a 1024 transparent canvas (safe zone)
  const S=1024, fg=new Jimp(S,S,0x00000000);
  const c1=cropped.clone(); c1.scaleToFit(Math.round(S*0.72),Math.round(S*0.72));
  fg.composite(c1, Math.round((S-c1.bitmap.width)/2), Math.round((S-c1.bitmap.height)/2));
  await fg.writeAsync(`${outDir}/icon_fg.png`);

  // legacy icon: logo at ~80% on white square
  const leg=new Jimp(S,S,0xFFFFFFFF);
  const c2=cropped.clone(); c2.scaleToFit(Math.round(S*0.80),Math.round(S*0.80));
  leg.composite(c2, Math.round((S-c2.bitmap.width)/2), Math.round((S-c2.bitmap.height)/2));
  await leg.writeAsync(`${outDir}/icon.png`);
  console.log('icons written. logo bbox:', (maxx-minx+1)+'x'+(maxy-miny+1));
})();
