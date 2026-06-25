import 'dart:js_interop';

@JS('eval')
external JSAny? _eval(JSString code);

/// Tarayıcıda Web Audio API ile kısa, kuru bir 'tık' sesi çalar.
void playWebBeep() {
  const js = r'''
  (function(){
    try {
      var Ctx = window.AudioContext || window.webkitAudioContext;
      if (!Ctx) return;
      if (!window.__hoppAudioCtx) window.__hoppAudioCtx = new Ctx();
      var ctx = window.__hoppAudioCtx;
      if (ctx.state === 'suspended') ctx.resume();
      var now = ctx.currentTime;
      var osc = ctx.createOscillator();
      var gain = ctx.createGain();
      osc.type = 'square';
      osc.frequency.setValueAtTime(1500, now);
      gain.gain.setValueAtTime(0.18, now);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.03);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.035);
    } catch(e) {}
  })();
  ''';
  _eval(js.toJS);
}
