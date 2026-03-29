set script_dir [file dirname [file normalize [info script]]]
set ip_root [file join $script_dir ip_repo servo_pwm_rx]
set component_xml [file join $ip_root component.xml]

file delete -force $ip_root
file mkdir $ip_root

foreach item {bd drivers hdl src xgui component.xml} {
    file copy -force [file join $script_dir $item] [file join $ip_root $item]
}

set core [ipx::open_core $component_xml]
ipx::update_checksums $core
ipx::check_integrity $core
ipx::save_core $core
