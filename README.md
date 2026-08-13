<h1><strong>Circulate</strong></h1>
<p><a href="README.md">English</a> | <a href="README.zh-CN.md">中文</a></p>
<p><strong>Fork / macOS version:</strong> This repository is a macOS-focused fork of <a href="https://github.com/GullDSP/Circulate-VST">GullDSP/Circulate-VST</a>. Version 3.0.1 is based on upstream source commit <code>65236c9</code> (<code>v2.0.1.1</code> in the original repository). This fork adds Universal 2 VST3/AUv2 builds, macOS PKG/DMG packaging, knob double-click reset, corrected factory defaults, and nine independent raster keyframes supplied by the author while preserving the original DSP.</p>
<p>Circulate is an allpass filter-based phase dispersion effect. The allpass filters, while leaving the frequency spectrum untouched, cause selective phase offsets around the chosen center frequency. These offsets present themselves as hollow and metallic short reverberation-like effects, useful for adding a dynamic metallic character to sounds. The effect is most pronounced on transient material, such as bass stabs, drum hits and plucks.</p>
<img width="660" height="398" alt="Circulate macOS preview" src="resource/readme/circulate-macos-preview.png" />

<h3>Download</h3>
<ul>
<li><strong>macOS Universal 2:</strong> <a href="https://github.com/komakizhu/Circulate-VST-macOS/releases">PKG / DMG releases</a> for Intel and Apple Silicon.</li>
<li><strong>Windows installer:</strong> <a href="https://github.com/komakizhu/Circulate-VST-macOS/releases/download/v2.0.3-macos/Circulate-Windows-VST3-Setup.exe">Circulate-Windows-VST3-Setup.exe</a>.</li>
<li><strong>Windows original ZIP:</strong> <a href="https://github.com/GullDSP/Circulate-VST/releases/download/v2.0.1.1/circulate-vst3-v2_0_1.zip">circulate-vst3-v2_0_1.zip</a> from upstream <code>v2.0.1.1</code>.</li>
</ul>
<h3>Demo</h3>
https://www.youtube.com/watch?v=rluT0xgxPuI


www.youtube.com/watch?v=tcsrC33vn1s&t=1s
<h3>Features</h3>
<ul>
<li>Sample accurate parameters and automation. Suitable for fast and complex automation and control via DAW modulators (for example Ableton LFOs)</li>
<li>Up to 64 stages of allpass dipsersion with variable Q (Resonance).</li>
<li>Center frequency can be controlled in Hz, or by selecting a MIDI note as the center.</li>
<li>Optional positive or negative feedback through the filter bank to create spectral effects. Similar to a steep phaser</li>
</ul>
<h3>Parameters</h3>
<ul>
<li><strong>Center</strong> - Center frequency of the allpass filter(s) in Hz. Click the display to type in a precise value.</li>
<li><strong>Pitch</strong> - Sets the center frequency through MIDI note</li>
<li><strong>Det</strong> - Allows smooth offset (+/- 1 Octave) of the center frequency from the selected MIDI note</li>
<li><strong>Focus</strong> - The Q factor, or 'Resonance' of the allpass filters. Lower Q values spread the phase smearing over a wider range, higher values focus the smearing tighter around the center.</li>
<li><strong>Depth</strong> - Sets the number of allpass filters in the filter bank, up to a maximum of 64.</li>
<li><strong>Feed</strong> - Feedback is introduced into the filter bank, this *will* lead to frequency spectrum changes, through cancelling or boosting affected frequencies.</li>

<h3>Version 2</h3>
<li>Resizable UI (right click - UI Zoom).</li>
<li>CPU use improvements.</li>
<li>Fixed Ableton UI bug when switching from Hz to semitone control.</li>
<li>Fixed strange bounce to audio behaviour in some DAWs.</li>
<li>Can manually enter a frequency (in Hz).</li>

<h3>macOS fork 3.0.1</h3>
<ul>
<li>Double-click any knob to restore its factory default; Control/Ctrl-click remains supported.</li>
<li>Hold <strong>Shift</strong> while dragging any knob for approximately 10× finer adjustment; Shift can be pressed or released during the same drag.</li>
<li>Corrected the Note reset value to the E4 midpoint and the Depth reset value to 32.</li>
<li>Added nine independent bird keyframe images from the supplied 3x3 sheet. Depth 0–7 shows keyframe 0, 8–15 shows keyframe 1, and so on; Depth 64 shows keyframe 8. The view jumps directly between source images, with no path redraw, interpolation, overlay, opacity crossfade or runtime animation.</li>
<li>The nine source cells are the complete Depth states in strict reading order: 0, 8, 16, 24, 32, 40, 48, 56 and 64. The renderer only removes the grid/background and applies fixed whole-image placement; it does not redraw, blend or synthesize feather detail.</li>
<li>Added a restrained “macOS version by komaki” credit linked to the fork repository while retaining GullDSP attribution.</li>
</ul>

<h3>Acknowledgements</h3>
<ul>
<li>This project is built using the Steinberg VST 3 SDK(https://www.steinberg.net/developers/).</li>
<li>VST is a trademark of Steinberg Media Technologies GmbH.</li>
<img width="200" height="187" alt="XXXXXXXX_snapshot_2 0x" src="https://steinbergmedia.github.io/vst3_dev_portal/resources/licensing_3.png" />

</ul>

<h3>Building the macOS VST3 plugin</h3>
<p>The project can be built as Universal 2 VST3 and AUv2 bundles for Intel and Apple Silicon Macs. The Steinberg VST3 SDK and Apple AudioUnitSDK are included as Git submodules.</p>
<pre><code>git clone --recurse-submodules https://github.com/komakizhu/Circulate-VST-macOS.git
cd Circulate-VST-macOS
cmake -S . -B build-macos -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
  -DSMTG_ENABLE_VSTGUI_SUPPORT=ON \
  -DSMTG_CREATE_PLUGIN_LINK=OFF
cmake --build build-macos -j1</code></pre>
<p>The resulting VST3 bundle is <code>build-macos/VST3/Release/Circulate.vst3</code>. For AUv2, use the Xcode generator and enable <code>CIRCULATE_ENABLE_AUV2</code>:</p>
<pre><code>cmake -S . -B build-macos-au -G Xcode \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
  -DSMTG_ENABLE_VSTGUI_SUPPORT=ON \
  -DSMTG_CREATE_PLUGIN_LINK=OFF \
  -DCIRCULATE_ENABLE_AUV2=ON \
  -DCIRCULATE_AUV2_STAGING_DIR="$PWD/outputs"
cmake --build build-macos-au --config Release</code></pre>
<p>To produce the distributable DMG after both bundles are available in <code>outputs/</code>, run <code>packaging/build-release.sh</code>. The script creates the Universal 2 PKG and DMG and installs to the system audio plug-in directories when the PKG is run.</p>
