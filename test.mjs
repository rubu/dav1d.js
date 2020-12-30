import dav1d from "./dav1d.mjs";

const isNode = typeof global !== "undefined";
const isStandaloneWasm = true;

(async () => {
  let obu = null;
  let fs = null;
  let debug = false;
  if (isNode) {
    debug = process.env.NODE_ENV === 'development'
  } else {
    const urlParams = new URLSearchParams(window.location.search);
    debug = urlParams.get('debug') !== null;
  }
  const wasmPath = debug ? "dav1d.debug.wasm" : "dav1d.wasm";
  console.log(`using dav1d wasm build from ${wasmPath}`)
  let opts = {};

  if (isNode) {
    fs = await import("fs");
    opts.wasmData = fs.readFileSync(wasmPath);
    obu = fs.readFileSync("test.obu");
  } else {
    if (!debug) {
      opts.wasmData = await fetch(wasmPath).then(res => res.arrayBuffer());
    } else {
      opts.wasmURL = `http://localhost:8000/${wasmPath}`
    }
    obu = await fetch("test.obu").then(res => res.arrayBuffer());
  }
  const d = await dav1d.create(opts);

  console.time("bmp copy");
  const {width, height, data} = d.decodeFrameAsBMP(obu);
  console.timeEnd("bmp copy");
  console.log("decoded "+width+"x"+height+" frame ("+data.byteLength+" bytes)");
  if (isNode) {
    fs.writeFileSync("test.bmp", data);
  }

  console.time("bmp ref");
  const data2 = d.unsafeDecodeFrameAsBMP(obu);
  console.timeEnd("bmp ref");
  console.log("decoded frame ("+data2.byteLength+" bytes)");
  if (isNode) {
    fs.writeFileSync("test2.bmp", data2);
  } else {
    const blob = new Blob(isStandaloneWasm ? [data] : [data2], {type: "image/bmp"});
    const blobURL = URL.createObjectURL(blob);
    const img = document.createElement("img");
    img.src = blobURL;
    document.body.appendChild(img);
  }
  d.unsafeCleanup();

})().catch(err => {
  console.error(err);
  if (isNode) {
    process.exit(1);
  }
});
