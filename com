<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>AeroLearn 3D — Interactive Airplane Explorer</title>
<link href="https://fonts.googleapis.com/css2?family=Space+Mono:wght@400;700&family=Barlow:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
:root{
  --bg:#06090F;
  --panel:rgba(8,14,24,0.92);
  --border:rgba(0,200,255,0.15);
  --accent:#00C8FF;
  --green:#00FF88;
  --yellow:#FFB700;
  --purple:#A78BFA;
  --red:#FF4560;
  --text:#D4E8F0;
  --muted:#4A6070;
}
html,body{width:100%;height:100%;overflow:hidden;background:var(--bg);}
body{font-family:'Barlow',sans-serif;}
#three-canvas{position:fixed;inset:0;z-index:0;}
 
/* TOP BAR */
.topbar{position:fixed;top:0;left:0;right:0;z-index:100;display:flex;align-items:center;justify-content:space-between;padding:0 1.5rem;height:52px;background:rgba(6,9,15,0.9);backdrop-filter:blur(16px);border-bottom:1px solid var(--border);}
.logo{font-family:'Space Mono',monospace;font-size:15px;color:var(--accent);letter-spacing:3px;}
.logo span{color:var(--text);}
.view-hint{font-size:11px;font-family:'Space Mono',monospace;color:var(--muted);letter-spacing:1px;}
.angle-indicator{font-size:11px;font-family:'Space Mono',monospace;color:var(--accent);background:rgba(0,200,255,0.08);border:1px solid var(--border);padding:4px 12px;border-radius:4px;}
 
/* LABELS */
.label{position:fixed;pointer-events:none;z-index:50;transform:translate(-50%,-50%);transition:opacity 0.3s;}
.label-dot{width:10px;height:10px;border-radius:50%;border:2px solid;position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);animation:pulse 2.5s ease-in-out infinite;}
.label-line{position:absolute;top:50%;left:50%;transform-origin:left center;height:1px;opacity:0.6;}
.label-box{position:absolute;white-space:nowrap;background:rgba(6,9,15,0.88);backdrop-filter:blur(8px);border:1px solid;border-radius:4px;padding:4px 10px;font-family:'Space Mono',monospace;font-size:10px;font-weight:700;letter-spacing:1px;cursor:pointer;pointer-events:all;transition:all 0.2s;}
.label-box:hover{transform:scale(1.05);}
.label-sub{font-size:9px;font-weight:400;opacity:0.7;display:block;margin-top:1px;font-family:'Barlow',sans-serif;letter-spacing:0.5px;}
@keyframes pulse{0%,100%{box-shadow:0 0 0 0 currentColor;}50%{box-shadow:0 0 0 6px transparent;}}
 
/* INFO PANEL */
.info-panel{position:fixed;right:0;top:52px;bottom:0;width:300px;background:var(--panel);border-left:1px solid var(--border);backdrop-filter:blur(16px);z-index:100;display:flex;flex-direction:column;transform:translateX(100%);transition:transform 0.35s cubic-bezier(0.4,0,0.2,1);}
.info-panel.open{transform:none;}
.info-close{position:absolute;top:1rem;right:1rem;width:28px;height:28px;border-radius:50%;background:rgba(255,255,255,0.05);border:1px solid var(--border);color:var(--muted);font-size:14px;cursor:pointer;display:flex;align-items:center;justify-content:center;}
.info-close:hover{color:var(--text);}
.info-top{padding:1.5rem;border-bottom:1px solid var(--border);}
.info-num{font-size:10px;font-family:'Space Mono',monospace;color:var(--muted);margin-bottom:4px;letter-spacing:1.5px;}
.info-name{font-size:20px;font-weight:700;line-height:1.1;margin-bottom:3px;}
.info-type{font-size:11px;color:var(--muted);font-family:'Space Mono',monospace;}
.info-scroll{flex:1;overflow-y:auto;padding:1.2rem;}
.info-desc{font-size:13px;line-height:1.8;color:var(--text);margin-bottom:1.2rem;}
.stats-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:1.2rem;}
.stat{background:rgba(0,200,255,0.04);border:1px solid var(--border);border-radius:6px;padding:0.7rem;}
.stat-val{font-family:'Space Mono',monospace;font-size:13px;font-weight:700;margin-bottom:2px;}
.stat-key{font-size:10px;color:var(--muted);}
.facts-title{font-size:10px;font-family:'Space Mono',monospace;color:var(--muted);letter-spacing:1.5px;text-transform:uppercase;margin-bottom:8px;}
.fact{background:rgba(0,200,255,0.03);border-left:2px solid var(--accent);padding:0.7rem 0.8rem;border-radius:0 6px 6px 0;font-size:12px;line-height:1.6;color:var(--text);margin-bottom:6px;}
 
/* BOTTOM ANGLE PANEL */
.angle-panel{position:fixed;bottom:1.5rem;left:50%;transform:translateX(-50%);z-index:100;background:rgba(6,9,15,0.88);backdrop-filter:blur(12px);border:1px solid var(--border);border-radius:12px;padding:0.6rem 1rem;display:flex;align-items:center;gap:12px;}
.angle-btn{font-size:11px;font-family:'Space Mono',monospace;padding:5px 14px;border-radius:6px;border:1px solid var(--border);background:transparent;color:var(--muted);cursor:pointer;transition:all 0.2s;letter-spacing:1px;}
.angle-btn:hover,.angle-btn.active{background:rgba(0,200,255,0.1);border-color:var(--accent);color:var(--accent);}
.angle-sep{width:1px;height:20px;background:var(--border);}
.ctrl-btn{width:32px;height:32px;border-radius:6px;border:1px solid var(--border);background:transparent;color:var(--muted);font-size:14px;cursor:pointer;transition:all 0.2s;display:flex;align-items:center;justify-content:center;}
.ctrl-btn:hover{border-color:var(--accent);color:var(--accent);}
 
/* VISIBLE LIST */
.visible-panel{position:fixed;left:0;top:52px;bottom:0;width:220px;background:var(--panel);border-right:1px solid var(--border);backdrop-filter:blur(16px);z-index:100;overflow-y:auto;padding:1rem 0;}
.vp-title{font-size:10px;font-family:'Space Mono',monospace;color:var(--muted);letter-spacing:2px;padding:0 1rem 0.8rem;text-transform:uppercase;}
.vp-item{display:flex;align-items:center;gap:8px;padding:7px 1rem;cursor:pointer;transition:all 0.15s;border-left:2px solid transparent;}
.vp-item:hover,.vp-item.active{background:rgba(0,200,255,0.05);border-left-color:var(--accent);}
.vp-dot{width:7px;height:7px;border-radius:50%;flex-shrink:0;}
.vp-name{font-size:12px;font-weight:500;}
.vp-cat{font-size:10px;color:var(--muted);font-family:'Space Mono',monospace;}
.vp-item.visible .vp-name{color:var(--text);}
.vp-item:not(.visible) .vp-name{color:var(--muted);opacity:0.5;}
.vp-section{font-size:10px;color:var(--muted);letter-spacing:1.5px;text-transform:uppercase;padding:0.8rem 1rem 0.3rem;font-family:'Space Mono',monospace;border-top:1px solid var(--border);margin-top:0.5rem;}
 
/* DRAG HINT */
.drag-hint{position:fixed;bottom:5rem;left:50%;transform:translateX(-50%);font-size:11px;font-family:'Space Mono',monospace;color:var(--muted);opacity:0.7;letter-spacing:1px;pointer-events:none;transition:opacity 1s;}
.drag-hint.hide{opacity:0;}
 
::-webkit-scrollbar{width:3px;}
::-webkit-scrollbar-thumb{background:var(--border);}
</style>
</head>
<body>
 
<canvas id="three-canvas"></canvas>
 
<!-- TOP BAR -->
<div class="topbar">
  <div class="logo">AERO<span>LEARN</span> <span style="font-size:10px;color:var(--muted);margin-left:8px;">3D EXPLORER</span></div>
  <div class="view-hint" id="viewHint">DRAG TO ROTATE · SCROLL TO ZOOM · CLICK PART TO INSPECT</div>
  <div class="angle-indicator" id="angleInd">ANGLE: 0°</div>
</div>
 
<!-- LEFT — VISIBLE COMPONENTS -->
<div class="visible-panel" id="visiblePanel">
  <div class="vp-title">Components</div>
  <div id="compList"></div>
</div>
 
<!-- RIGHT — INFO PANEL -->
<div class="info-panel" id="infoPanel">
  <button class="info-close" onclick="closeInfo()">✕</button>
  <div class="info-top">
    <div class="info-num" id="iNum"></div>
    <div class="info-name" id="iName"></div>
    <div class="info-type" id="iType"></div>
  </div>
  <div class="info-scroll">
    <p class="info-desc" id="iDesc"></p>
    <div class="stats-grid" id="iStats"></div>
    <div class="facts-title">Did you know?</div>
    <div id="iFacts"></div>
  </div>
</div>
 
<!-- BOTTOM CONTROLS -->
<div class="angle-panel">
  <button class="angle-btn active" id="ab-side" onclick="snapView('side')">SIDE</button>
  <button class="angle-btn" id="ab-front" onclick="snapView('front')">FRONT</button>
  <button class="angle-btn" id="ab-top" onclick="snapView('top')">TOP</button>
  <button class="angle-btn" id="ab-rear" onclick="snapView('rear')">REAR</button>
  <button class="angle-btn" id="ab-iso" onclick="snapView('iso')">ISO</button>
  <div class="angle-sep"></div>
  <button class="ctrl-btn" onclick="zoomBy(1.2)" title="Zoom In">+</button>
  <button class="ctrl-btn" onclick="zoomBy(0.8)" title="Zoom Out">−</button>
  <button class="ctrl-btn" onclick="resetCam()" title="Reset">⟳</button>
  <button class="ctrl-btn" id="autoBtn" onclick="toggleAuto()" title="Auto-rotate">▶</button>
</div>
 
<div class="drag-hint" id="dragHint">DRAG TO ROTATE THE AIRCRAFT</div>
 
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script>
// ─── DATA ───────────────────────────────────────────────────────────────────
const COMPS = {
  fuselage:{name:'Fuselage',type:'Main Body Structure',color:'#00C8FF',num:'01',
    desc:'The fuselage is the central body of the aircraft connecting all major components. It houses the cockpit, passenger cabin, and cargo hold. Built from aluminum alloy frames and skin panels, it must withstand pressurization up to 60 kPa differential at cruise altitude.',
    stats:[['~37m','Length'],['4.1m','Diameter'],['60 kPa','Pressure Δ'],['Al-Li','Material']],
    facts:['The fuselage skin is only 2–3mm thick but reinforced by 185 internal frames.','At 35,000 ft the cabin is pressurized to equivalent of 8,000 ft altitude.','A full fuselage can flex several centimeters in turbulence without damage.'],
    views:['side','front','rear','iso'],angle:[0,360]},
  nose:{name:'Nose Cone',type:'Radome / Aerodynamic',color:'#00C8FF',num:'02',
    desc:'The nose cone (radome) houses the weather radar antenna. Its composite fiberglass construction is transparent to radar waves. The pointed shape splits incoming air to minimize drag and must survive bird strikes at cruise speed.',
    stats:[['100m','Radar range'],['GFRP','Material'],['4 kg bird','Strike rated'],['Heated','Anti-ice']],
    facts:['The nose cone can withstand a 4 lb bird impact at full cruise speed without penetration.','Weather radar inside detects storms up to 320 km ahead.','The nose is painted non-reflectively to reduce radar interference.'],
    views:['side','front','iso'],angle:[-30,30]},
  cockpit:{name:'Cockpit',type:'Flight Deck',color:'#00FF88',num:'03',
    desc:'The flight deck houses two pilots and thousands of instruments. Modern glass cockpits use multi-function LCD displays replacing hundreds of analog gauges. Fly-by-wire computers translate pilot inputs into precise control surface movements.',
    stats:[['400+','Switches'],['6 MFDs','Screens'],['2 pilots','Crew'],['FMS','Automation']],
    facts:['A modern cockpit has over 400 switches, buttons, and controls for two pilots.','The windshield is electrically heated and can withstand a 4 lb bird impact.','Autopilot can execute 95% of a flight including landing in near-zero visibility.'],
    views:['front','side','iso'],angle:[-45,45]},
  mainwing:{name:'Main Wings',type:'Primary Lift Surface',color:'#FFB700',num:'04',
    desc:'Wings generate lift via Bernoulli principle — the curved airfoil shape accelerates airflow over the top surface, creating lower pressure above than below. A Boeing 737 wing spans 34 meters and must structurally support 2.5× maximum takeoff weight. Wing tanks hold 26,000 liters of jet fuel each.',
    stats:[['34m','Wingspan'],['135m²','Area'],['26,000L','Fuel/wing'],['25°','Sweep']],
    facts:['Wingtips can flex upward by 3–4 meters during flight due to lift forces.','Winglets reduce induced drag by 5%, saving significant fuel annually.','The airfoil shape generates 4× more lift per m² than a flat surface.'],
    views:['front','top','iso'],angle:[60,120]},
  aileron:{name:'Ailerons',type:'Primary Roll Control',color:'#FFB700',num:'05',
    desc:'Ailerons are hinged panels on the outer trailing edge of each wing that deflect in opposite directions to roll the aircraft left or right. When left aileron goes up, right goes down — creating asymmetric lift that banks the aircraft into turns.',
    stats:[['±25°','Deflection'],['Outer wing','Location'],['Hydraulic','Actuator'],['Roll','Function']],
    facts:['Ailerons move differentially — one up, one down simultaneously.','At high speeds, inner high-speed ailerons prevent wing flex issues.','The word aileron comes from French, meaning little wing.'],
    views:['top','rear','iso'],angle:[100,180]},
  flaps:{name:'Flaps',type:'High-Lift Device',color:'#FFB700',num:'06',
    desc:'Flaps extend from the inner trailing edge of the wings during takeoff and landing. They increase wing camber and area, generating more lift at lower speeds — reducing approach speed by 30–40 knots and enabling operation from shorter runways.',
    stats:[['0–40°','Range'],['Inner wing','Position'],['Hydraulic','Drive'],['T/O & Land','Phase']],
    facts:['Full flap extension reduces landing speed from ~280 to ~220 km/h.','Boeing 737 uses triple-slotted Fowler flaps for maximum lift.','Extending flaps also increases drag, helping slow the aircraft on approach.'],
    views:['top','rear','iso'],angle:[80,160]},
  slats:{name:'Slats',type:'Leading Edge Device',color:'#FFB700',num:'07',
    desc:'Slats extend from the leading edge of the wings to increase curvature at the front. They allow the wing to maintain lift at higher angles of attack without stalling, reducing stall speed by up to 15 knots during takeoff and landing.',
    stats:[['0–27°','Deflection'],['Leading edge','Location'],['15 kts','Speed reduction'],['Anti-stall','Function']],
    facts:['The slot between slat and wing accelerates airflow, keeping it attached.','Slats reduce stall speed by up to 15 knots compared to clean wing.','On some aircraft slats and flaps are linked and extend simultaneously.'],
    views:['front','top','iso'],angle:[60,130]},
  spoilers:{name:'Spoilers / Airbrakes',type:'Drag & Lift Dump',color:'#FF4560',num:'08',
    desc:'Spoiler panels on the upper wing surface raise to disrupt airflow, reducing lift and increasing drag. Used as in-flight speed brakes, ground spoilers on landing (dumping lift to increase wheel braking), and asymmetrically to assist roll control.',
    stats:[['0–60°','Deflection'],['Upper wing','Position'],['Ground+Air','Modes'],['80% lift','Ground dump']],
    facts:['Ground spoilers deploy on touchdown, reducing lift by up to 80%.','In-flight spoilers extend to 30° max to act as speed brakes.','Asymmetric deployment provides 50% of roll control at low speeds.'],
    views:['top','iso'],angle:[70,150]},
  vtail:{name:'Vertical Stabilizer',type:'Directional Stability',color:'#A78BFA',num:'09',
    desc:'The vertical fin provides yaw (directional) stability, acting as a weather vane to keep the aircraft pointing into the relative wind. Without it the aircraft would yaw uncontrollably. It also carries navigation lights, antennae, and may house the APU exhaust.',
    stats:[['6m','Height'],['Yaw stab','Function'],['Single fin','Config'],['CFRP','Material']],
    facts:['The vertical stabilizer stands ~12m above the ground — tallest point of the aircraft.','It generates a sideways restoring force when the aircraft yaws off heading.','The fin is hollow and routes hydraulic lines, cables, and the APU exhaust.'],
    views:['rear','side','iso'],angle:[140,220]},
  rudder:{name:'Rudder',type:'Yaw Control Surface',color:'#A78BFA',num:'10',
    desc:'The rudder is the movable section of the vertical fin, operated by foot pedals. It deflects left/right to yaw the nose, coordinate turns, counteract engine failure asymmetry, and align the aircraft with the runway during crosswind landings.',
    stats:[['±25°','Deflection'],['Vertical fin','Position'],['Dual section','Design'],['Fly-by-wire','System']],
    facts:['Rudder is critical during engine-out — prevents yaw toward dead engine.','Airlines limit rudder input at high speed to avoid structural exceedance.','Pilots use rudder to de-crab the aircraft just before crosswind touchdown.'],
    views:['rear','side','iso'],angle:[150,210]},
  htail:{name:'Horizontal Stabilizer',type:'Pitch Stability',color:'#A78BFA',num:'11',
    desc:'The horizontal stabilizer is the fixed tail surface providing pitch stability and preventing uncontrolled nose pitch. On modern jets it can rotate (variable incidence) via a trim jack screw to balance the aircraft for different weights and fuel states.',
    stats:[['10m','Span'],['Variable','Incidence'],['Pitch stab','Function'],['Trim jack','Mechanism']],
    facts:['H-stabilizer generates downward force to counteract nose-up tendency of wings.','It can be adjusted in 0.1° increments by autopilot to maintain level flight.','Provides larger pitch authority than the elevator alone.'],
    views:['rear','side','iso'],angle:[130,230]},
  elevator:{name:'Elevator',type:'Primary Pitch Control',color:'#A78BFA',num:'12',
    desc:'The elevator is the movable rear section of the horizontal tail. Pulling the control column deflects the elevator up — pushing the tail down and rotating the nose up to climb. Pushing forward causes descent. It is one of the three primary flight controls.',
    stats:[['±25°','Deflection'],['H-tail trailing','Location'],['Pitch','Function'],['FBW','System']],
    facts:['Modern aircraft use fly-by-wire — electrical signals replace mechanical cables.','Just a few degrees of elevator deflection produces a significant pitch rate.','Elevator authority is enhanced by the trimmable horizontal stabilizer.'],
    views:['rear','side','iso'],angle:[140,220]},
  engine:{name:'Turbofan Engines',type:'Propulsion System',color:'#FF4560',num:'13',
    desc:'High-bypass turbofan engines (CFM56) power the 737. Air enters through the large fan — 80% bypasses the core producing most thrust; the rest is compressed, burned at 1,600°C, and exhausted. Each engine produces 27,000 lbs of thrust and burns ~2,500 kg/hour of fuel.',
    stats:[['27,000 lbs','Thrust each'],['30,000 RPM','Fan speed'],['2,500 kg/hr','Fuel burn'],['1,600°C','Combustion']],
    facts:['Engines compress incoming air 30× before combustion reaches 1,600°C.','Fan blades spin at 3,000+ RPM at takeoff and are made of titanium alloy.','Bypass ratio 6:1 — 6 parts bypass the core for every 1 part that goes through it.'],
    views:['front','side','iso'],angle:[-60,60]},
  nacelle:{name:'Engine Nacelle',type:'Engine Housing',color:'#FF4560',num:'14',
    desc:'The nacelle is the aerodynamic pod surrounding the engine. It streamlines airflow, reduces noise via acoustic liners, and houses fire suppression systems, bleed air ducting, thrust reverser mechanisms, and quick-release maintenance access panels.',
    stats:[['Noise liner','Feature'],['CFRP+Al','Material'],['Clamshell','Access'],['20dB','Noise reduction']],
    facts:['Nacelle inlet lips are heated electrically to prevent ice ingestion.','Acoustic liners reduce engine noise by up to 20 dB.','Entire nacelle+engine can be replaced in under 24 hours for maintenance.'],
    views:['front','side','iso'],angle:[-70,70]},
  thrustrev:{name:'Thrust Reversers',type:'Deceleration System',color:'#FF4560',num:'15',
    desc:'Thrust reversers redirect engine bypass air forward to decelerate the aircraft after touchdown. Clamshell doors or cascade vanes deploy in about 3 seconds, reducing landing distance by 20–30% and reducing wear on wheel brakes.',
    stats:[['3 sec','Deploy time'],['30%','Decel contrib.'],['Hydraulic','Actuation'],['Ground only','Operation']],
    facts:['Thrust reversers reduce landing distance by approximately 20–30%.','They are only used on the ground — in-flight use could cause engine surge.','Pilots use idle reverse (not full) to avoid ingesting reversed exhaust.'],
    views:['rear','iso'],angle:[140,220]},
  nosegear:{name:'Nose Landing Gear',type:'Forward Undercarriage',color:'#00FF88',num:'16',
    desc:'The steerable nose gear under the cockpit supports 10% of aircraft weight and steers up to ±75° for ground maneuvering. It retracts rearward into the nose wheel well after takeoff. An oleo-pneumatic shock absorber cushions hard landings.',
    stats:[['10%','Weight share'],['±75°','Steering angle'],['Oleo-pneu','Shock absorber'],['12 sec','Retract time']],
    facts:['Nose wheel steering uses a captain-side tiller, separate from rudder pedals.','The nose wheel spins from 0 to 200 km/h in under one second at touchdown.','The oleo strut works like an oil-filled bicycle pump to absorb landing energy.'],
    views:['front','side','iso'],angle:[-20,20]},
  maingear:{name:'Main Landing Gear',type:'Primary Undercarriage',color:'#00FF88',num:'17',
    desc:'Two main gear bogies under the wings carry 90% of aircraft weight. Carbon-fiber multi-disc brakes with anti-skid systems absorb the kinetic energy of landing. Each tire inflated to 200 psi — 14× a car tire — and can handle hard landings up to 3G.',
    stats:[['90%','Weight share'],['200 psi','Tire pressure'],['Carbon disc','Brakes'],['Anti-skid','Safety system']],
    facts:['Main gear brakes can boil 600 liters of water in a rejected takeoff stop.','After an aborted takeoff, brakes glow red-hot and need 30–60 min to cool.','Each main gear tire is inflated to ~14× the pressure of a car tire.'],
    views:['front','side','iso'],angle:[-40,40]},
  apu:{name:'APU (Aux. Power Unit)',type:'Auxiliary Power',color:'#00FF88',num:'18',
    desc:'The Auxiliary Power Unit is a small jet engine in the tail cone. It provides electrical power and pressurized air for air conditioning and engine starting when the main engines are off. The APU allows the aircraft to be self-sufficient at the gate without external power.',
    stats:[['Tail cone','Location'],['Ground+Air','Operational'],['400Hz','AC Power'],['Bleed air','Start engines']],
    facts:['APU exhaust exits through the tail cone and is visible as a small circular vent.','It can generate enough electricity to power a small neighborhood.','On some aircraft the APU can be used in-flight as a backup power source.'],
    views:['rear','iso'],angle:[160,200]},
};
 
// ─── THREE.JS SETUP ─────────────────────────────────────────────────────────
const canvas = document.getElementById('three-canvas');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.setSize(window.innerWidth, window.innerHeight);
 
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x06090F);
scene.fog = new THREE.FogExp2(0x06090F, 0.018);
 
const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 200);
camera.position.set(12, 4, 0);
camera.lookAt(0, 0, 0);
 
// Lights
const ambient = new THREE.AmbientLight(0x112233, 0.8);
scene.add(ambient);
const dirLight = new THREE.DirectionalLight(0x00C8FF, 1.2);
dirLight.position.set(10, 15, 10);
dirLight.castShadow = true;
scene.add(dirLight);
const rimLight = new THREE.DirectionalLight(0x00FF88, 0.4);
rimLight.position.set(-10, -5, -10);
scene.add(rimLight);
const fillLight = new THREE.PointLight(0xFFB700, 0.3, 30);
fillLight.position.set(0, 8, 0);
scene.add(fillLight);
 
// Grid
const gridHelper = new THREE.GridHelper(40, 40, 0x0A1520, 0x0A1520);
gridHelper.position.y = -3.5;
scene.add(gridHelper);
 
// Materials
const mat = (color, emissive, opacity=1) => new THREE.MeshPhongMaterial({
  color: new THREE.Color(color),
  emissive: new THREE.Color(emissive || color).multiplyScalar(0.08),
  shininess: 60,
  transparent: opacity < 1,
  opacity,
  side: THREE.DoubleSide
});
 
// Meshes registry for raycasting
const meshMap = {}; // meshUUID -> compKey
const compMeshes = {}; // compKey -> [mesh,...]
const planeGroup = new THREE.Group();
scene.add(planeGroup);
 
function addMesh(key, geo, material, pos, rot, sca) {
  const mesh = new THREE.Mesh(geo, material);
  if (pos) mesh.position.set(...pos);
  if (rot) mesh.rotation.set(...rot);
  if (sca) mesh.scale.set(...sca);
  planeGroup.add(mesh);
  meshMap[mesh.uuid] = key;
  if (!compMeshes[key]) compMeshes[key] = [];
  compMeshes[key].push(mesh);
  return mesh;
}
 
// ─── BUILD AIRPLANE ─────────────────────────────────────────────────────────
 
// FUSELAGE — tapered cylinder
const fusGeo = new THREE.CylinderGeometry(0.55, 0.55, 9, 32);
const fusM = mat('#1A2F45', '#00C8FF');
addMesh('fuselage', fusGeo, fusM, [0,0,0], [0,0,Math.PI/2]);
 
// NOSE — cone
const noseGeo = new THREE.ConeGeometry(0.55, 2.5, 32);
const noseM = mat('#162840', '#00C8FF');
addMesh('nose', noseGeo, noseM, [5.75,0,0], [0,0,-Math.PI/2]);
 
// TAIL CONE
const tailConeGeo = new THREE.ConeGeometry(0.55, 1.5, 32);
addMesh('apu', tailConeGeo, mat('#142235','#00FF88'), [-5.25,0,0], [0,0,Math.PI/2]);
 
// COCKPIT WINDOWS — flat panel on nose
const ckpGeo = new THREE.BoxGeometry(1.2, 0.35, 0.8);
addMesh('cockpit', ckpGeo, mat('#1A5060','#00FF88'), [4.6,0.38,0]);
// side windows row
for(let i=-3;i<=2;i++){
  const wGeo = new THREE.BoxGeometry(0.01, 0.22, 0.28);
  addMesh('fuselage', wGeo, mat('#3A8FA8','#00C8FF'), [i*0.75, 0.56, 0]);
}
 
// MAIN WINGS — extruded trapezoid shape
function makeWing(side) {
  const s = side; // 1 or -1
  const shape = new THREE.Shape();
  shape.moveTo(0,0); shape.lineTo(1.5,0); shape.lineTo(0.5, 5.5*s); shape.lineTo(-0.3, 5.5*s); shape.closePath();
  const extGeo = new THREE.ExtrudeGeometry(shape, {depth:0.06, bevelEnabled:false});
  const wingM = mat('#1E3550','#FFB700');
  const m = addMesh('mainwing', extGeo, wingM, [-0.75, -0.05, 0], [0, 0, 0]);
  // proper placement
  m.position.set(-0.5, -0.1, 0);
  m.rotation.x = -Math.PI / 2;
  m.scale.z = s;
  return m;
}
makeWing(1); makeWing(-1);
 
// WINGLETS
function makeWinglet(side) {
  const geo = new THREE.BoxGeometry(0.08, 0.7, 0.3);
  addMesh('mainwing', geo, mat('#264560','#FFB700'), [-0.8, 0.3, side * 5.4]);
}
makeWinglet(1); makeWinglet(-1);
 
// AILERONS
function makeAileron(side) {
  const geo = new THREE.BoxGeometry(1.2, 0.05, 0.22);
  addMesh('aileron', geo, mat('#2A4060','#FFB700'), [-0.4, -0.06, side * 4.7]);
}
makeAileron(1); makeAileron(-1);
 
// FLAPS
function makeFlap(side) {
  const geo = new THREE.BoxGeometry(1.8, 0.05, 0.35);
  addMesh('flaps', geo, mat('#1A3050','#FFB700'), [0.1, -0.06, side * 2.8]);
}
makeFlap(1); makeFlap(-1);
 
// SLATS
function makeSlat(side) {
  const geo = new THREE.BoxGeometry(3.5, 0.04, 0.15);
  addMesh('slats', geo, mat('#162840','#FFB700'), [-0.3, -0.04, side * 2.8]);
}
makeSlat(1); makeSlat(-1);
 
// SPOILERS
function makeSpoiler(side) {
  const geo = new THREE.BoxGeometry(1.4, 0.04, 0.2);
  addMesh('spoilers', geo, mat('#3A1020','#FF4560'), [0, 0.05, side * 2.5]);
}
makeSpoiler(1); makeSpoiler(-1);
 
// ENGINES + NACELLES
function makeEngine(side) {
  // nacelle body
  const nacGeo = new THREE.CylinderGeometry(0.38, 0.32, 1.8, 24);
  addMesh('nacelle', nacGeo, mat('#1A2535','#FF4560'), [0.5, -0.42, side * 2.2], [0,0,Math.PI/2]);
  // fan inlet
  const fanGeo = new THREE.CylinderGeometry(0.38, 0.38, 0.08, 24);
  addMesh('engine', fanGeo, mat('#0D1822','#FF4560'), [1.42, -0.42, side * 2.2], [0,0,Math.PI/2]);
  // fan blades
  for(let b=0;b<9;b++){
    const a = (b/9)*Math.PI*2;
    const bladeGeo = new THREE.BoxGeometry(0.04, 0.34, 0.06);
    const bladeMesh = addMesh('engine', bladeGeo, mat('#1A3050','#FF4560'),
      [1.42, -0.42 + Math.sin(a)*0.18, side*2.2 + Math.cos(a)*0.18],
      [0, 0, a]
    );
  }
  // exhaust nozzle
  const exhGeo = new THREE.CylinderGeometry(0.28, 0.22, 0.3, 16);
  addMesh('thrustrev', exhGeo, mat('#1A1A1A','#FF4560'), [-0.6, -0.42, side * 2.2], [0,0,Math.PI/2]);
  // pylon (wing attachment)
  const pylGeo = new THREE.BoxGeometry(0.6, 0.3, 0.12);
  addMesh('nacelle', pylGeo, mat('#1A2535','#FF4560'), [0.5, -0.22, side * 2.2]);
}
makeEngine(1); makeEngine(-1);
 
// VERTICAL STABILIZER
const vtGeo = new THREE.Shape();
vtGeo.moveTo(0,0); vtGeo.lineTo(-1.5,0); vtGeo.lineTo(-2.2,2.4); vtGeo.lineTo(-1.2,2.4); vtGeo.closePath();
const vtExtGeo = new THREE.ExtrudeGeometry(vtGeo, {depth:0.07, bevelEnabled:false});
const vtM = addMesh('vtail', vtExtGeo, mat('#1E3550','#A78BFA'), [-3.5, 0.55, -0.035]);
 
// RUDDER
const rdShape = new THREE.Shape();
rdShape.moveTo(0,0); rdShape.lineTo(-0.6,0); rdShape.lineTo(-1.0,2.3); rdShape.lineTo(-0.3,2.3); rdShape.closePath();
const rdExtGeo = new THREE.ExtrudeGeometry(rdShape, {depth:0.04, bevelEnabled:false});
addMesh('rudder', rdExtGeo, mat('#22304A','#A78BFA'), [-3.6, 0.55, -0.02]);
 
// HORIZONTAL STABILIZERS
function makeHTail(side) {
  const shape = new THREE.Shape();
  shape.moveTo(0,0); shape.lineTo(0.8,0); shape.lineTo(0.2, 2.2*side); shape.lineTo(-0.4, 2.2*side); shape.closePath();
  const geo = new THREE.ExtrudeGeometry(shape, {depth:0.05, bevelEnabled:false});
  addMesh('htail', geo, mat('#1E3550','#A78BFA'), [-3.8, 0, 0], [0,0,0], [1,1,1]);
  const m = new THREE.Mesh(geo, mat('#1E3550','#A78BFA'));
  m.position.set(-3.8, 0.02, 0);
  m.rotation.x = -Math.PI/2;
  m.scale.z = side;
  planeGroup.add(m);
  meshMap[m.uuid] = 'htail';
  if(!compMeshes['htail']) compMeshes['htail']=[];
  compMeshes['htail'].push(m);
}
makeHTail(1); makeHTail(-1);
 
// ELEVATORS
function makeElevator(side) {
  const geo = new THREE.BoxGeometry(0.9, 0.04, 0.3);
  addMesh('elevator', geo, mat('#22304A','#A78BFA'), [-4.15, 0, side * 1.6]);
}
makeElevator(1); makeElevator(-1);
 
// NOSE GEAR
const ngStrut = new THREE.CylinderGeometry(0.04, 0.04, 0.9, 8);
addMesh('nosegear', ngStrut, mat('#1A3020','#00FF88'), [4.0, -1.0, 0]);
const ngAxle = new THREE.CylinderGeometry(0.03, 0.03, 0.4, 8);
addMesh('nosegear', ngAxle, mat('#1A3020','#00FF88'), [4.0, -1.45, 0], [0,0,Math.PI/2]);
[-0.2,0.2].forEach(z=>{
  const wGeo = new THREE.CylinderGeometry(0.16, 0.16, 0.1, 16);
  addMesh('nosegear', wGeo, mat('#111','#00FF88'), [4.0, -1.45, z], [Math.PI/2,0,0]);
});
 
// MAIN GEAR
function makeMainGear(side) {
  const strut = new THREE.CylinderGeometry(0.055, 0.055, 1.1, 8);
  addMesh('maingear', strut, mat('#1A3020','#00FF88'), [0.5, -1.05, side * 1.1]);
  const axle = new THREE.CylinderGeometry(0.03, 0.03, 0.6, 8);
  addMesh('maingear', axle, mat('#1A3020','#00FF88'), [0.5, -1.6, side * 1.1], [0,0,Math.PI/2]);
  [-0.3,0,0.3].forEach(dz=>{
    const wGeo = new THREE.CylinderGeometry(0.2, 0.2, 0.12, 16);
    addMesh('maingear', wGeo, mat('#111','#00FF88'), [0.5, -1.6, side*1.1+dz], [Math.PI/2,0,0]);
  });
}
makeMainGear(1); makeMainGear(-1);
 
// ─── ORBIT CONTROLS (manual) ────────────────────────────────────────────────
let isDragging = false, lastX = 0, lastY = 0;
let spherical = { theta: 0, phi: Math.PI/2.5, r: 14 };
let targetSpherical = { ...spherical };
let autoRotate = false;
let interacted = false;
 
function sphericalToCart(s) {
  return {
    x: s.r * Math.sin(s.phi) * Math.cos(s.theta),
    y: s.r * Math.cos(s.phi),
    z: s.r * Math.sin(s.phi) * Math.sin(s.theta)
  };
}
 
canvas.addEventListener('mousedown', e => { isDragging = true; lastX = e.clientX; lastY = e.clientY; interacted = true; document.getElementById('dragHint').classList.add('hide'); });
window.addEventListener('mouseup', () => isDragging = false);
window.addEventListener('mousemove', e => {
  if (!isDragging) return;
  const dx = (e.clientX - lastX) * 0.008;
  const dy = (e.clientY - lastY) * 0.005;
  targetSpherical.theta -= dx;
  targetSpherical.phi = Math.max(0.3, Math.min(Math.PI * 0.7, targetSpherical.phi + dy));
  lastX = e.clientX; lastY = e.clientY;
});
canvas.addEventListener('wheel', e => { e.preventDefault(); targetSpherical.r = Math.max(4, Math.min(30, targetSpherical.r + e.deltaY * 0.02)); }, { passive:false });
 
// Touch
let lastTouchDist = 0;
canvas.addEventListener('touchstart', e => {
  interacted = true;
  document.getElementById('dragHint').classList.add('hide');
  if(e.touches.length===1){ isDragging=true; lastX=e.touches[0].clientX; lastY=e.touches[0].clientY; }
  if(e.touches.length===2){ lastTouchDist=Math.hypot(e.touches[0].clientX-e.touches[1].clientX, e.touches[0].clientY-e.touches[1].clientY); }
});
canvas.addEventListener('touchend', () => isDragging=false);
canvas.addEventListener('touchmove', e => {
  e.preventDefault();
  if(e.touches.length===1 && isDragging){
    const dx=(e.touches[0].clientX-lastX)*0.008, dy=(e.touches[0].clientY-lastY)*0.006;
    targetSpherical.theta-=dx;
    targetSpherical.phi=Math.max(0.3,Math.min(Math.PI*0.7,targetSpherical.phi+dy));
    lastX=e.touches[0].clientX; lastY=e.touches[0].clientY;
  }
  if(e.touches.length===2){
    const d=Math.hypot(e.touches[0].clientX-e.touches[1].clientX, e.touches[0].clientY-e.touches[1].clientY);
    targetSpherical.r=Math.max(4,Math.min(30, targetSpherical.r*(lastTouchDist/d)));
    lastTouchDist=d;
  }
},{ passive:false });
 
function zoomBy(f){ targetSpherical.r=Math.max(4,Math.min(30,targetSpherical.r/f)); }
function resetCam(){ targetSpherical={theta:0,phi:Math.PI/2.5,r:14}; selectedComp=null; updateInfoPanel(null); clearHighlight(); }
function toggleAuto(){ autoRotate=!autoRotate; document.getElementById('autoBtn').textContent=autoRotate?'⏸':'▶'; }
 
const snapAngles = {
  side:  { theta: 0,          phi: Math.PI/2,   r: 14 },
  front: { theta: Math.PI/2,  phi: Math.PI/2.2, r: 12 },
  rear:  { theta: -Math.PI/2, phi: Math.PI/2.2, r: 12 },
  top:   { theta: 0,          phi: 0.35,         r: 14 },
  iso:   { theta: Math.PI/5,  phi: Math.PI/3.2, r: 16 },
};
function snapView(v){
  const a=snapAngles[v]; targetSpherical={...a};
  document.querySelectorAll('.angle-btn').forEach(b=>b.classList.remove('active'));
  document.getElementById('ab-'+v).classList.add('active');
}
 
// ─── RAYCASTING ──────────────────────────────────────────────────────────────
const raycaster = new THREE.Raycaster();
const mouse = new THREE.Vector2();
let selectedComp = null;
let clickPos = null;
 
canvas.addEventListener('click', e => {
  const rect = canvas.getBoundingClientRect();
  if(clickPos && (Math.abs(e.clientX-clickPos.x)+Math.abs(e.clientY-clickPos.y))>6) return;
  mouse.x = ((e.clientX-rect.left)/rect.width)*2-1;
  mouse.y = -((e.clientY-rect.top)/rect.height)*2+1;
  raycaster.setFromCamera(mouse, camera);
  const allMeshes = Object.values(compMeshes).flat();
  const hits = raycaster.intersectObjects(allMeshes);
  if(hits.length > 0){
    const key = meshMap[hits[0].object.uuid];
    if(key) { selectComp(key); return; }
  }
  // deselect
  selectedComp=null; updateInfoPanel(null); clearHighlight();
});
canvas.addEventListener('mousedown', e => { clickPos={x:e.clientX,y:e.clientY}; });
 
// ─── HIGHLIGHT ───────────────────────────────────────────────────────────────
const originalColors = {};
function saveOrigColors(){
  Object.keys(compMeshes).forEach(key=>{
    compMeshes[key].forEach(m=>{
      if(!originalColors[m.uuid]) originalColors[m.uuid]={ color: m.material.color.clone(), emissive: m.material.emissive.clone() };
    });
  });
}
setTimeout(saveOrigColors, 100);
 
function clearHighlight(){
  Object.keys(compMeshes).forEach(key=>{
    compMeshes[key].forEach(m=>{
      if(originalColors[m.uuid]){
        m.material.color.copy(originalColors[m.uuid].color);
        m.material.emissive.copy(originalColors[m.uuid].emissive);
        m.material.opacity=1;
      }
    });
  });
}
 
function highlightComp(key){
  clearHighlight();
  const col = new THREE.Color(COMPS[key]?.color || '#00C8FF');
  Object.keys(compMeshes).forEach(k=>{
    compMeshes[k].forEach(m=>{
      if(k===key){
        m.material.color.set(col);
        m.material.emissive.set(col); m.material.emissive.multiplyScalar(0.3);
      } else {
        m.material.color.multiplyScalar(0.25);
        m.material.emissive.multiplyScalar(0.1);
      }
    });
  });
}
 
function selectComp(key){
  selectedComp=key;
  highlightComp(key);
  updateInfoPanel(key);
  document.querySelectorAll('.vp-item').forEach(el=>{
    el.classList.toggle('active', el.dataset.key===key);
  });
}
 
// ─── INFO PANEL ──────────────────────────────────────────────────────────────
function updateInfoPanel(key){
  const panel = document.getElementById('infoPanel');
  if(!key){ panel.classList.remove('open'); return; }
  const c = COMPS[key];
  if(!c){ panel.classList.remove('open'); return; }
  document.getElementById('iNum').textContent = `COMPONENT · ${c.num} / ${Object.keys(COMPS).length}`;
  document.getElementById('iName').textContent = c.name;
  document.getElementById('iName').style.color = c.color;
  document.getElementById('iType').textContent = c.type;
  document.getElementById('iDesc').textContent = c.desc;
  document.getElementById('iStats').innerHTML = c.stats.map(([v,k])=>`<div class="stat"><div class="stat-val" style="color:${c.color}">${v}</div><div class="stat-key">${k}</div></div>`).join('');
  document.getElementById('iFacts').innerHTML = c.facts.map(f=>`<div class="fact">${f}</div>`).join('');
  panel.classList.add('open');
}
function closeInfo(){ document.getElementById('infoPanel').classList.remove('open'); selectedComp=null; clearHighlight(); }
 
// ─── LABELS ───────────────────────────────────────────────────────────────────
// 3D label positions for each component
const labelPos3D = {
  fuselage:  new THREE.Vector3(0, 0.8, 0),
  nose:      new THREE.Vector3(6.5, 0.5, 0),
  cockpit:   new THREE.Vector3(5.0, 1.0, 0),
  mainwing:  new THREE.Vector3(-0.5, 0.5, 4.5),
  aileron:   new THREE.Vector3(-0.4, 0.3, 5.0),
  flaps:     new THREE.Vector3(0.3, 0.2, 3.2),
  slats:     new THREE.Vector3(0.5, 0.2, 3.0),
  spoilers:  new THREE.Vector3(0.1, 0.4, 2.8),
  vtail:     new THREE.Vector3(-4.2, 2.5, 0),
  rudder:    new THREE.Vector3(-4.5, 2.0, 0),
  htail:     new THREE.Vector3(-4.0, 0.5, 2.0),
  elevator:  new THREE.Vector3(-4.3, 0.3, 1.6),
  engine:    new THREE.Vector3(1.0, -0.2, 2.8),
  nacelle:   new THREE.Vector3(0.5, -0.9, 2.4),
  thrustrev: new THREE.Vector3(-0.8, -0.7, 2.3),
  nosegear:  new THREE.Vector3(4.0, -1.8, 0.5),
  maingear:  new THREE.Vector3(0.5, -2.0, 1.8),
  apu:       new THREE.Vector3(-6.2, 0.2, 0),
};
 
const labelEls = {};
function createLabels(){
  Object.keys(COMPS).forEach(key=>{
    const c = COMPS[key];
    const div = document.createElement('div');
    div.className = 'label';
    div.dataset.key = key;
    div.innerHTML = `
      <div class="label-dot" style="color:${c.color};background:${c.color};width:10px;height:10px;border-radius:50%;box-shadow:0 0 8px ${c.color};"></div>
      <div class="label-line" id="ll-${key}" style="background:${c.color};"></div>
      <div class="label-box" style="border-color:${c.color}88;color:${c.color};" onclick="selectComp('${key}')">
        ${c.name}
        <span class="label-sub">${c.type}</span>
      </div>`;
    document.body.appendChild(div);
    labelEls[key] = div;
  });
}
createLabels();
 
function updateLabels(){
  const W = window.innerWidth, H = window.innerHeight;
  const camDir = new THREE.Vector3();
  camera.getWorldDirection(camDir);
  const camPos = camera.position.clone();
  const camTheta = Math.atan2(camPos.z, camPos.x) * 180 / Math.PI;
  const camPhi = Math.atan2(Math.sqrt(camPos.x*camPos.x+camPos.z*camPos.z), camPos.y) * 180/Math.PI;
  const isTop = camPhi < 35;
  const isBottom = camPhi > 130;
 
  Object.keys(COMPS).forEach(key=>{
    const pos3d = labelPos3D[key];
    if(!pos3d){ if(labelEls[key]) labelEls[key].style.opacity='0'; return; }
 
    // Project to screen
    const wp = pos3d.clone();
    wp.project(camera);
    const sx = (wp.x*0.5+0.5)*W;
    const sy = (-wp.y*0.5+0.5)*H;
 
    // Visibility: behind camera?
    if(wp.z > 1){ labelEls[key].style.opacity='0'; return; }
 
    // Determine visibility based on camera angle
    const comp = COMPS[key];
    let visible = true;
 
    // Occlusion heuristic: hide labels on the far side
    const toComp = pos3d.clone().sub(camPos).normalize();
    const dot = toComp.dot(camDir);
    if(dot < 0) { labelEls[key].style.opacity='0'; return; }
 
    // View-based visibility
    const normTheta = ((camTheta % 360) + 360) % 360;
    // For symmetric parts (wings, engines, gear), show based on which side camera is on
    if(['mainwing','aileron','flaps','slats','spoilers','engine','nacelle','thrustrev','htail','elevator','maingear'].includes(key)){
      // These have mirrored versions; show one set based on camera Z angle
      const camZ = camPos.z;
      if(pos3d.z > 0 && camZ < -1) { labelEls[key].style.opacity='0'; return; }
      if(pos3d.z < 0 && camZ > 1) { labelEls[key].style.opacity='0'; return; }
    }
 
    // Top-only visible when looking from top
    if(['spoilers','slats','flaps','aileron'].includes(key) && !isTop && camPhi > 75) {
      // fade based on how much from top we are
    }
 
    // Underside gear — visible from below or side
    if(['nosegear','maingear'].includes(key) && camPhi < 55 && Math.abs(camPos.y) > 5){
      labelEls[key].style.opacity='0'; return;
    }
 
    // Tail — visible from rear or side
    if(['vtail','rudder','apu','htail','elevator','thrustrev'].includes(key)){
      const camX = camPos.x;
      if(camX > 3) { labelEls[key].style.opacity='0'; return; }
    }
 
    // Nose/cockpit — visible from front or side
    if(['nose','cockpit'].includes(key)){
      if(camPos.x < -3) { labelEls[key].style.opacity='0'; return; }
    }
 
    const el = labelEls[key];
    el.style.left = sx + 'px';
    el.style.top = sy + 'px';
 
    const isSelected = selectedComp === key;
    const alpha = selectedComp ? (isSelected ? 1 : 0.35) : 0.9;
    el.style.opacity = alpha;
    el.style.zIndex = isSelected ? 60 : 50;
 
    // Label offset direction (always push label away from center of screen)
    const ox = sx > W/2 ? 70 : -70;
    const oy = sy > H/2 ? 30 : -30;
 
    const lLine = el.querySelector('[id^="ll-"]');
    if(lLine){
      const dist = Math.sqrt(ox*ox+oy*oy);
      const angle = Math.atan2(oy, ox) * 180/Math.PI;
      lLine.style.width = dist+'px';
      lLine.style.transform = `rotate(${angle}deg)`;
    }
 
    const lBox = el.querySelector('.label-box');
    if(lBox){
      lBox.style.left = (ox + (ox > 0 ? 0 : -lBox.offsetWidth)) + 'px';
      lBox.style.top = (oy - lBox.offsetHeight/2) + 'px';
      if(isSelected){
        lBox.style.borderColor = COMPS[key].color;
        lBox.style.boxShadow = `0 0 12px ${COMPS[key].color}66`;
      } else {
        lBox.style.boxShadow = 'none';
      }
    }
  });
}
 
// ─── COMPONENT LIST ──────────────────────────────────────────────────────────
function buildCompList(){
  const sections = [
    { title:'Airframe', keys:['fuselage','nose','cockpit'] },
    { title:'Wings & Control', keys:['mainwing','aileron','flaps','slats','spoilers'] },
    { title:'Tail', keys:['vtail','rudder','htail','elevator'] },
    { title:'Propulsion', keys:['engine','nacelle','thrustrev','apu'] },
    { title:'Landing Gear', keys:['nosegear','maingear'] },
  ];
  const list = document.getElementById('compList');
  list.innerHTML = '';
  sections.forEach(sec=>{
    const secEl = document.createElement('div');
    secEl.className='vp-section'; secEl.textContent=sec.title;
    list.appendChild(secEl);
    sec.keys.forEach(key=>{
      const c = COMPS[key];
      const item = document.createElement('div');
      item.className='vp-item visible'; item.dataset.key=key;
      item.innerHTML=`<div class="vp-dot" style="background:${c.color}"></div><div><div class="vp-name">${c.name}</div><div class="vp-cat">${c.num}</div></div>`;
      item.addEventListener('click',()=>selectComp(key));
      list.appendChild(item);
    });
  });
}
buildCompList();
 
// ─── ANGLE INDICATOR ─────────────────────────────────────────────────────────
function updateAngleIndicator(){
  const theta = ((spherical.theta * 180/Math.PI) % 360 + 360) % 360;
  const phi = spherical.phi * 180/Math.PI;
  let desc = '';
  const normT = theta > 180 ? theta-360 : theta;
  if(Math.abs(normT) < 20) desc='SIDE VIEW';
  else if(normT > 70 && normT < 110) desc='FRONT VIEW';
  else if((normT > 160 || normT < -160)) desc='REAR VIEW';
  else if(normT < -70 && normT > -110) desc='REAR VIEW';
  else if(phi < 40) desc='TOP VIEW';
  else desc='ISO VIEW';
  document.getElementById('angleInd').textContent=`${desc} · ${Math.abs(Math.round(normT))}°`;
  document.getElementById('viewHint').textContent = getViewHint(normT, phi);
}
 
function getViewHint(t, phi){
  if(phi < 40) return 'TOP VIEW — Seeing: Wings · Flaps · Slats · Spoilers · Engines';
  if(Math.abs(t) < 25) return 'SIDE VIEW — Seeing: Fuselage · Wings · Engines · Tail · Landing Gear';
  if(t > 60 && t < 120) return 'FRONT VIEW — Seeing: Nose · Cockpit · Wings · Engines · Landing Gear';
  if(Math.abs(t) > 150) return 'REAR VIEW — Seeing: Tail · Rudder · Elevators · APU · Thrust Reversers';
  return 'ISO VIEW — Seeing: Full aircraft from 3/4 angle';
}
 
// ─── RENDER LOOP ─────────────────────────────────────────────────────────────
function lerp(a,b,t){ return a+(b-a)*t; }
 
const clock = new THREE.Clock();
function animate(){
  requestAnimationFrame(animate);
  const dt = clock.getDelta();
 
  if(autoRotate) targetSpherical.theta += 0.004;
 
  // Smooth camera
  spherical.theta = lerp(spherical.theta, targetSpherical.theta, 0.08);
  spherical.phi   = lerp(spherical.phi,   targetSpherical.phi,   0.08);
  spherical.r     = lerp(spherical.r,     targetSpherical.r,     0.08);
 
  const p = sphericalToCart(spherical);
  camera.position.set(p.x, p.y, p.z);
  camera.lookAt(0, 0, 0);
 
  // Subtle plane float
  planeGroup.position.y = Math.sin(Date.now()*0.0006)*0.06;
 
  updateAngleIndicator();
  updateLabels();
  renderer.render(scene, camera);
}
animate();
 
window.addEventListener('resize', ()=>{
  camera.aspect = window.innerWidth/window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});
 
// Auto-hide drag hint
setTimeout(()=>{ if(!interacted) document.getElementById('dragHint').classList.add('hide'); }, 4000);
</script>
</body>
</html>
