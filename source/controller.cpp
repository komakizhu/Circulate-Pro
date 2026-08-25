//------------------------------------------------------------------------
// Copyright(c) 2025 Anis Dadou (GullDSP)
//------------------------------------------------------------------------

#include "controller.h"
#include "cids.h"
#include "base/source/fstreamer.h"

#include <cstddef>
#include <cstring>
#include <utility>

#define MAX_ZOOM_FACTOR_LIMIT 16
#define MIN_ZOOM_FACTOR_LIMIT 0.1



using namespace Steinberg;

namespace CirculateVST {

//------------------------------------------------------------------------
// CirculateController Implementation
//------------------------------------------------------------------------
tresult PLUGIN_API CirculateController::initialize (FUnknown* context)
{
	// Here the Plug-in will be instantiated

	//---do not forget to call parent ------
	tresult result = EditControllerEx1::initialize (context);
	if (result != kResultOk)
	{
		return result;
	}

	CIRCULATE_PARAMS::registerParameters(parameters);

	setKnobMode(Steinberg::Vst::KnobModes::kLinearMode);
	
	return result;
}

//------------------------------------------------------------------------
tresult PLUGIN_API CirculateController::terminate ()
{
	// Here the Plug-in will be de-instantiated, last possibility to remove some memory!

	//---do not forget to call parent ------
	return EditControllerEx1::terminate ();
}

//------------------------------------------------------------------------
tresult PLUGIN_API CirculateController::setComponentState (IBStream* state)
{
	// Here you get the state of the component (Processor part)
	if (!state)
		return kResultFalse;

	IBStreamer streamer(state, kLittleEndian);
	
	double depth, center, note, focus, type, offset, bypass, feed;

	// Read values in the SAME ORDER the processor wrote them
	if (streamer.readDouble(depth) == false) return kResultFalse;
	if (streamer.readDouble(center) == false) return kResultFalse;
	if (streamer.readDouble(note) == false) return kResultFalse;
	if (streamer.readDouble(focus) == false) return kResultFalse;
	if (streamer.readDouble(type) == false) return kResultFalse;
	if (streamer.readDouble(offset) == false) return kResultFalse;
	if (streamer.readDouble(bypass) == false) return kResultFalse;
	if (streamer.readDouble(feed) == false) return kResultFalse;
	
	// Update the controller's parameter objects.
	setParamNormalized(CIRCULATE_PARAMS::kDepth, depth);
	setParamNormalized(CIRCULATE_PARAMS::kCenter, center);
	setParamNormalized(CIRCULATE_PARAMS::kCenterST, note);
	setParamNormalized(CIRCULATE_PARAMS::kFocus, focus);
	setParamNormalized(CIRCULATE_PARAMS::kSetSwitch, type);
	setParamNormalized(CIRCULATE_PARAMS::kNoteOffset, offset);
	setParamNormalized(CIRCULATE_PARAMS::kBypass, bypass);
	setParamNormalized(CIRCULATE_PARAMS::kFeed, feed);

	updateSwitchState(type);

	return kResultOk;
}

//------------------------------------------------------------------------
tresult PLUGIN_API CirculateController::setState (IBStream* state)
{

	// Get state of switch
	float switch_value = getParamNormalized(CIRCULATE_PARAMS::kSetSwitch);

	updateSwitchState(switch_value);

	if (state) {
		Steinberg::IBStreamer streamer(state, kLittleEndian);
		int id = -1;
		double value = 0;
		if (streamer.readInt32(id) && streamer.readDouble(value)) {

			if (id == kZoomFactorID) {

				if ((value > MIN_ZOOM_FACTOR_LIMIT) && (value < MAX_ZOOM_FACTOR_LIMIT)) {
					currentZoomFactor = value;
					if (currentEditor) 	currentEditor->setZoomFactor(currentZoomFactor);

				}

			}

		}

	}

	return kResultTrue;
}

//------------------------------------------------------------------------
tresult PLUGIN_API CirculateController::getState (IBStream* state)
{
	if (state) {
		Steinberg::IBStreamer streamer(state, kLittleEndian);
		streamer.writeInt32(kZoomFactorID);
		streamer.writeDouble(currentZoomFactor);
		// don't need to write the switch state as it is stored in the processor

	}

	return kResultTrue;
}

//------------------------------------------------------------------------
IPlugView* PLUGIN_API CirculateController::createView (FIDString name)
{
	if (FIDStringsEqual (name, Vst::ViewType::kEditor))
	{


		currentEditor = new CustomEditor (this, "view", "editor.uidesc");
		auto* customEditor = static_cast<CustomEditor*>(currentEditor);
		if (customEditor) {
			// Update editor
			customEditor->setSwitchToHz(switchIsHzState);
			customEditor->setZoomFactor(currentZoomFactor);

		}


		return currentEditor;
	}
	return nullptr;
}

//------------------------------------------------------------------------
VSTGUI::CView* CirculateController::createCustomView (
	VSTGUI::UTF8StringPtr name, const VSTGUI::UIAttributes&,
	const VSTGUI::IUIDescription* description, VSTGUI::VST3Editor* editor)
{
	if (!name || !description)
		return nullptr;

	if (std::strcmp (name, "DepthBirdView") == 0)
	{
		static constexpr const char* keyframeNames[] = {
			"depth-bird-keyframe-00",
			"depth-bird-keyframe-01",
			"depth-bird-keyframe-02",
			"depth-bird-keyframe-03",
			"depth-bird-keyframe-04",
			"depth-bird-keyframe-05",
			"depth-bird-keyframe-06",
			"depth-bird-keyframe-07",
			"depth-bird-keyframe-08",
		};
		DepthBirdView::KeyframeArray keyframes;
		for (size_t index = 0; index < keyframes.size (); ++index)
			keyframes[index] = VSTGUI::shared (description->getBitmap (keyframeNames[index]));

		const auto depthTag = description->getTagForName ("Depth");
		return new DepthBirdView (VSTGUI::CRect (0, 0, 50, 50), editor, depthTag,
			std::move (keyframes));
	}

	if (std::strcmp (name, "ProBadgeView") == 0)
	{
		auto badgeBitmap = VSTGUI::shared (description->getBitmap ("pro-badge"));
		VSTGUI::CColor textColor (195, 195, 195, 255);
		description->getColor ("BG", textColor);
		return new ProBadgeView (VSTGUI::CRect (0, 0, 20, 14),
			std::move (badgeBitmap), description->getFont ("ProBadge"), textColor);
	}

	if (std::strcmp (name, "CreditLinkView") == 0)
	{
		VSTGUI::CColor normalColor (100, 100, 100, 255);
		description->getColor ("FG2", normalColor);
		VSTGUI::CColor hoverColor (60, 60, 60, 255);
		return new CreditLinkView (VSTGUI::CRect (0, 0, 220, 20),
			description->getFont ("Credit"), normalColor, hoverColor);
	}

	return nullptr;
}




//------------------------------------------------------------------------
} // namespace CirculateVST
