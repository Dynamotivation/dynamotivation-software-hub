"""Contrast spot-check with CSS hex colors and sRGB alpha composition."""
import argparse
import json


def color(value):
    raw = value.removeprefix("#")
    if len(raw) not in (6, 8):
        raise argparse.ArgumentTypeError("Use #RRGGBB or #RRGGBBAA (alpha last).")
    try:
        values = tuple(int(raw[i:i + 2], 16) / 255 for i in range(0, len(raw), 2))
    except ValueError as error:
        raise argparse.ArgumentTypeError("Color must contain hexadecimal digits.") from error
    return values if len(values) == 4 else (*values, 1.0)


def composite(top, bottom):
    alpha = top[3] + bottom[3] * (1 - top[3])
    if alpha == 0:
        return (0.0, 0.0, 0.0, 0.0)
    return (*((top[i] * top[3] + bottom[i] * bottom[3] * (1 - top[3])) / alpha
              for i in range(3)), alpha)


def luminance(rgba):
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
              for c in rgba[:3]]
    return sum(c * weight for c, weight in zip(linear, (0.2126, 0.7152, 0.0722)))


def positive(value):
    number = float(value)
    if not 1 <= number <= 21:
        raise argparse.ArgumentTypeError("Threshold must be between 1 and 21.")
    return number


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--foreground", type=color, required=True)
    parser.add_argument("--background", type=color, required=True)
    parser.add_argument("--underlay", type=color)
    parser.add_argument("--threshold", type=positive, default=4.5)
    args = parser.parse_args()
    background = args.background
    if background[3] < 1:
        if args.underlay is None or args.underlay[3] < 1:
            parser.error("A translucent background requires an opaque --underlay.")
        background = composite(background, args.underlay)
    foreground = composite(args.foreground, background)
    low, high = sorted((luminance(foreground), luminance(background)))
    ratio = (high + 0.05) / (low + 0.05)
    print(json.dumps({"ratio": round(ratio, 6), "threshold": args.threshold,
                      "passes": ratio >= args.threshold,
                      "effective_foreground_rgb": [round(c * 255, 3) for c in foreground[:3]],
                      "effective_background_rgb": [round(c * 255, 3) for c in background[:3]]}))
    return 0 if ratio >= args.threshold else 1


if __name__ == "__main__":
    raise SystemExit(main())
