package presentation.style;

import haxe.Resource;
import haxe.ui.Toolkit;
import haxe.ui.core.Component;

/**
 * PlatformStyleManager
 * 
 * Provides a unified cross-platform styling and metric override system for HaxeUI widgets.
 * Allows overriding widget margins, paddings, sizing, and fonts on a per-operating-system
 * basis through both dedicated platform stylesheets and programmatic metric adjustments.
 */
class PlatformStyleManager {
    public static var currentPlatform(default, null):PlatformType = detectPlatform();

    /**
     * Detects the operating system using compile-time defines and runtime fallbacks.
     */
    public static function detectPlatform():PlatformType {
        #if windows
        return PlatformType.Windows;
        #elseif mac
        return PlatformType.Mac;
        #elseif linux
        return PlatformType.Linux;
        #else
        var sysName = Sys.systemName().toLowerCase();
        if (sysName.indexOf("window") != -1) return PlatformType.Windows;
        if (sysName.indexOf("mac") != -1 || sysName.indexOf("darwin") != -1) return PlatformType.Mac;
        if (sysName.indexOf("linux") != -1) return PlatformType.Linux;
        return PlatformType.Unknown;
        #end
    }

    /**
     * Returns the CSS class identifier corresponding to the active OS.
     */
    public static function getPlatformCssClass():String {
        return switch (currentPlatform) {
            case PlatformType.Windows: "platform-windows";
            case PlatformType.Mac: "platform-mac";
            case PlatformType.Linux: "platform-linux";
            case PlatformType.Unknown: "platform-unknown";
        }
    }

    /**
     * Applies platform-specific stylesheet rules and classes to the UI hierarchy.
     */
    public static function initializePlatformStyles():Void {
        var resourceName = switch (currentPlatform) {
            case PlatformType.Windows: "style_windows";
            case PlatformType.Mac: "style_mac";
            case PlatformType.Linux: "style_linux";
            case PlatformType.Unknown: null;
        };

        if (resourceName != null) {
            var platformCss = Resource.getString(resourceName);
            if (platformCss != null && platformCss.length > 0) {
                // Ingest and merge platform-specific stylesheet rules into HaxeUI's style engine
                Toolkit.styleSheet.parse(platformCss);
            }
        }
    }

    /**
     * Decorates a root component with platform styling classes and metric adjustments.
     */
    public static function applyToRoot(root:Component):Void {
        if (root == null) return;

        // Add root-level platform marker class (e.g. .platform-windows)
        root.addClass(getPlatformCssClass());

        // Fine-tune programmatic quirks if necessary (e.g. native wxWidgets sizing gaps)
        applyWidgetQuirks(root);
    }

    /**
     * Programmatic adjustments for platform-specific widget quirks (margins, spacing)
     * that might not be fully controlled by CSS alone in native wxWidgets wrappers.
     */
    public static function applyWidgetQuirks(component:Component):Void {
        switch (currentPlatform) {
            case PlatformType.Windows:
                // Windows native controls usually look best with tight, compact spacing
                // e.g., default dialog margin 7-11 dialog units

            case PlatformType.Mac:
                // macOS HIG prefers generous breathing room and distinct button heights

            case PlatformType.Linux:
                // Linux GTK3 standards prefer medium padding with consistent widget borders

            case PlatformType.Unknown:
                // Keep default configuration
        }
    }
}
