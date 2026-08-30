#pragma once

#include "public.sdk/source/common/openurl.h"
#include "vstgui/lib/cbitmap.h"
#include "vstgui/lib/cbuttonstate.h"
#include "vstgui/lib/cdrawcontext.h"
#include "vstgui/lib/cframe.h"
#include "vstgui/lib/controls/ccontrol.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <utility>

namespace CirculateVST {

class DepthBirdView final : public VSTGUI::CControl
{
public:
	static constexpr uint16_t kKeyframeCount = 9;
	using KeyframeArray = std::array<VSTGUI::SharedPointer<VSTGUI::CBitmap>, kKeyframeCount>;

	DepthBirdView (const VSTGUI::CRect& size, VSTGUI::IControlListener* listener, int32_t tag,
				   KeyframeArray keyframeBitmaps)
	: CControl (size, listener, tag)
	, keyframes (std::move (keyframeBitmaps))
	{
		setMouseEnabled (false);
	}

	DepthBirdView (const DepthBirdView& other)
	: CControl (other)
	, keyframes (other.keyframes)
	, baseFrame (other.baseFrame)
	{
		setMouseEnabled (false);
	}

	VSTGUI::CBaseObject* newCopy () const override { return new DepthBirdView (*this); }

	void setValueNormalized (float value) override
	{
		CControl::setValueNormalized (value);
		const auto newFrame = normalizedToFrame (getValueNormalized ());
		if (newFrame == baseFrame)
			return;

		baseFrame = newFrame;
		invalid ();
	}

	void draw (VSTGUI::CDrawContext* context) override
	{
		if (auto& keyframe = keyframes[baseFrame])
			keyframe->draw (context, getViewSize ());
		setDirty (false);
	}

private:
	static uint16_t normalizedToFrame (float value)
	{
		// The nine supplied source images are held in strict Depth bands:
		// 0/8/16/24/32/40/48/56, with the final image reserved for 64.
		const auto clamped = std::clamp (value, 0.f, 1.f);
		const auto depth = static_cast<uint16_t> (std::lround (clamped * 64.f));
		return std::min<uint16_t> (depth / 8, kKeyframeCount - 1);
	}

	KeyframeArray keyframes;
	uint16_t baseFrame {0};
};

class ProBadgeView final : public VSTGUI::CView
{
public:
	ProBadgeView (const VSTGUI::CRect& size,
				  VSTGUI::SharedPointer<VSTGUI::CBitmap> bitmap,
				  VSTGUI::CFontRef font, VSTGUI::CColor textColor)
	: CView (size), bitmap (std::move (bitmap)), font (font), textColor (textColor)
	{
		setMouseEnabled (false);
	}

	ProBadgeView (const ProBadgeView& other)
	: CView (other), bitmap (other.bitmap), font (other.font), textColor (other.textColor)
	{
		setMouseEnabled (false);
	}

	VSTGUI::CBaseObject* newCopy () const override { return new ProBadgeView (*this); }

	void draw (VSTGUI::CDrawContext* context) override
	{
		if (bitmap)
			bitmap->draw (context, getViewSize ());
		// At small logical sizes the generated foil texture can visually merge
		// the lettering. Render the exact background-colored knockout on top so
		// PRO remains legible at 1x while the AI foil remains the badge surface.
		context->setFont (font);
		context->setFontColor (textColor);
		context->drawString ("PRO", getViewSize (), VSTGUI::kCenterText, true);
		setDirty (false);
	}

protected:
	~ProBadgeView () noexcept override = default;

private:
	VSTGUI::SharedPointer<VSTGUI::CBitmap> bitmap;
	VSTGUI::CFontRef font {nullptr};
	VSTGUI::CColor textColor;
};

class CreditLinkView final : public VSTGUI::CView
{
public:
	static constexpr auto kPrefix = "v3.1.0 \xC2\xB7 GullDSP \xC2\xB7 ";
	static constexpr auto kLinkText = "macOS version by komaki";
	static constexpr auto kProjectUrl = "https://github.com/komakizhu/Circulate-VST-macOS";

	CreditLinkView (const VSTGUI::CRect& size, VSTGUI::CFontRef font,
				VSTGUI::CColor normalColor, VSTGUI::CColor hoverColor)
	: CView (size), font (font), normalColor (normalColor), hoverColor (hoverColor)
	{
		setMouseEnabled (true);
	}

	void draw (VSTGUI::CDrawContext* context) override
	{
		context->setFont (font);
		const auto prefixWidth = context->getStringWidth (kPrefix);
		const auto linkWidth = context->getStringWidth (kLinkText);
		const auto viewRect = getViewSize ();
		const auto textLeft = viewRect.right - prefixWidth - linkWidth;
		const VSTGUI::CRect prefixRect (textLeft, viewRect.top, textLeft + prefixWidth, viewRect.bottom);
		const VSTGUI::CRect linkDrawRect (prefixRect.right, viewRect.top, viewRect.right, viewRect.bottom);
		const auto glyphBandHeight = std::ceil (font ? font->getSize () : 7.) + 2.;
		const auto glyphBandTop = viewRect.getCenter ().y - glyphBandHeight * 0.5;
		linkRect = VSTGUI::CRect (linkDrawRect.left, glyphBandTop,
			linkDrawRect.right, glyphBandTop + glyphBandHeight);

		context->setFontColor (normalColor);
		context->drawString (kPrefix, prefixRect, VSTGUI::kLeftText, true);
		context->setFontColor (hovered ? hoverColor : normalColor);
		context->drawString (kLinkText, linkDrawRect, VSTGUI::kLeftText, true);
		if (hovered)
		{
			context->setFrameColor (hoverColor);
			context->setLineWidth (0.75);
			const auto underlineY = linkRect.bottom - 1.0;
			context->drawLine (VSTGUI::CPoint (linkRect.left, underlineY),
							   VSTGUI::CPoint (linkRect.right, underlineY));
		}
		setDirty (false);
	}

	VSTGUI::CMouseEventResult onMouseDown (VSTGUI::CPoint& where,
										  const VSTGUI::CButtonState& buttons) override
	{
		armed = buttons.isLeftButton () && !buttons.isDoubleClick () && linkRect.pointInside (where);
		return armed ? VSTGUI::kMouseEventHandled : VSTGUI::kMouseEventNotHandled;
	}

	VSTGUI::CMouseEventResult onMouseUp (VSTGUI::CPoint& where,
										const VSTGUI::CButtonState&) override
	{
		const bool shouldOpen = armed && linkRect.pointInside (where);
		armed = false;
		if (shouldOpen)
		{
			Steinberg::String url (kProjectUrl);
			Steinberg::openURLInDefaultApplication (url);
			return VSTGUI::kMouseEventHandled;
		}
		return VSTGUI::kMouseEventNotHandled;
	}

	VSTGUI::CMouseEventResult onMouseMoved (VSTGUI::CPoint& where,
										   const VSTGUI::CButtonState&) override
	{
		setHovered (linkRect.pointInside (where));
		return VSTGUI::kMouseEventHandled;
	}

	VSTGUI::CMouseEventResult onMouseEntered (VSTGUI::CPoint& where,
											 const VSTGUI::CButtonState&) override
	{
		setHovered (linkRect.pointInside (where));
		return VSTGUI::kMouseEventHandled;
	}

	VSTGUI::CMouseEventResult onMouseExited (VSTGUI::CPoint&,
											const VSTGUI::CButtonState&) override
	{
		armed = false;
		setHovered (false);
		return VSTGUI::kMouseEventHandled;
	}

protected:
	~CreditLinkView () noexcept override = default;

private:
	void setHovered (bool state)
	{
		if (hovered == state)
			return;
		hovered = state;
		if (auto* frame = getFrame ())
			frame->setCursor (hovered ? VSTGUI::kCursorPointingHand : VSTGUI::kCursorDefault);
		invalid ();
	}

	VSTGUI::CFontRef font {nullptr};
	VSTGUI::CColor normalColor;
	VSTGUI::CColor hoverColor;
	VSTGUI::CRect linkRect;
	bool hovered {false};
	bool armed {false};
};

} // namespace CirculateVST
