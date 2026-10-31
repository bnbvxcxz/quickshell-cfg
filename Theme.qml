pragma Singleton
import QtQuick

QtObject {
	
	readonly property color background: "#0e1513"
	
	readonly property color error: "#ffb4ab"
	
	readonly property color error_container: "#93000a"
	
	readonly property color inverse_on_surface: "#2b3230"
	
	readonly property color inverse_primary: "#006a60"
	
	readonly property color inverse_surface: "#dde4e1"
	
	readonly property color on_background: "#dde4e1"
	
	readonly property color on_error: "#690005"
	
	readonly property color on_error_container: "#ffdad6"
	
	readonly property color on_primary: "#003731"
	
	readonly property color on_primary_container: "#9ef2e4"
	
	readonly property color on_primary_fixed: "#00201c"
	
	readonly property color on_primary_fixed_variant: "#005048"
	
	readonly property color on_secondary: "#1c3531"
	
	readonly property color on_secondary_container: "#cce8e2"
	
	readonly property color on_secondary_fixed: "#05201c"
	
	readonly property color on_secondary_fixed_variant: "#334b47"
	
	readonly property color on_surface: "#dde4e1"
	
	readonly property color on_surface_variant: "#bec9c6"
	
	readonly property color on_tertiary: "#153349"
	
	readonly property color on_tertiary_container: "#cce5ff"
	
	readonly property color on_tertiary_fixed: "#001e31"
	
	readonly property color on_tertiary_fixed_variant: "#2d4961"
	
	readonly property color outline: "#899390"
	
	readonly property color outline_variant: "#3f4947"
	
	readonly property color primary: "#82d5c8"
	
	readonly property color primary_container: "#005048"
	
	readonly property color primary_fixed: "#9ef2e4"
	
	readonly property color primary_fixed_dim: "#82d5c8"
	
	readonly property color scrim: "#000000"
	
	readonly property color secondary: "#b1ccc6"
	
	readonly property color secondary_container: "#334b47"
	
	readonly property color secondary_fixed: "#cce8e2"
	
	readonly property color secondary_fixed_dim: "#b1ccc6"
	
	readonly property color shadow: "#000000"
	
	readonly property color source_color: "#1a4e47"
	
	readonly property color surface: "#0e1513"
	
	readonly property color surface_bright: "#343b39"
	
	readonly property color surface_container: "#1a211f"
	
	readonly property color surface_container_high: "#252b2a"
	
	readonly property color surface_container_highest: "#303635"
	
	readonly property color surface_container_low: "#161d1b"
	
	readonly property color surface_container_lowest: "#090f0e"
	
	readonly property color surface_dim: "#0e1513"
	
	readonly property color surface_tint: "#82d5c8"
	
	readonly property color surface_variant: "#3f4947"
	
	readonly property color tertiary: "#adcae6"
	
	readonly property color tertiary_container: "#2d4961"
	
	readonly property color tertiary_fixed: "#cce5ff"
	
	readonly property color tertiary_fixed_dim: "#adcae6"
	

	// Fallback typography (overridden automatically by BarMetrics via qt6ct)
	readonly property string fontFamily: "JetBrainsMono NFP"
	readonly property int fontSize: 10
	readonly property int cornerRadius: 10

	// Base Layout Metrics (pre-PPI scaling)
	readonly property int baseBarHeight: 22
	readonly property int basePillPadding: 6
	readonly property int baseSpacing: 4
	readonly property int baseDrawerWidth: 360
	readonly property int baseDrawerHeight: 600
}
