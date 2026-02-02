# -------------------------------------------------------------------------
# Standardized IP Analysis (키워드 매핑 방식)
# -------------------------------------------------------------------------
# [사용법]
# 1. 4bit 프로젝트에서 실행할 땐 아래 파일명을 "Selected_IP_Report_4bit.csv" 로 변경
# 2. 8bit 프로젝트에서 실행할 땐 아래 파일명을 "Selected_IP_Report_8bit.csv" 로 변경

set output_csv "Selected_IP_Report_4concat1.csv" 
set output_html "Selected_IP_Report_4concat1.html"

set fp [open $output_csv w]
set html [open $output_html w]

# -------------------------------------------------------------------------
# [핵심] 검색 키워드 설정
# 왼쪽이 "CSV에 저장될 이름(통일된 이름)", 오른쪽이 "검색할 키워드"입니다.
# -------------------------------------------------------------------------
array set target_map {
    "cooktimer"   "*myip_cooktimer*"
    "stopwatch"   "*myip_stopwatch*"
    "watch"       "*myip_watch*"
    "fnd_cntr"    "*myip_fnd_cntr*"
    "iic"         "*myip_iic*"
}

# Basys3 기준 리소스 총량
set TOTAL_LUT 20800
set TOTAL_FF 41600

puts "--- 표준화된 이름으로 IP 분석을 시작합니다... ---"

# HTML 헤더
puts $html "<!DOCTYPE html><html><head><title>IP Analysis</title>"
puts $html "<style>body{font-family:sans-serif;padding:20px;} table{border-collapse:collapse;width:100%;} th,td{border:1px solid #ddd;padding:8px;text-align:center;} th{background:#333;color:fff;} .fail{color:red;font-weight:bold;} .pass{color:green;}</style></head><body>"

# 1. Summary
set global_path [get_timing_paths -max_paths 1 -quiet]
set g_wns "N/A"
if {$global_path != ""} { set g_wns [get_property SLACK $global_path] }

puts $fp "--- \[SECTION 1\] SUMMARY ---"
puts $fp "Global WNS,$g_wns,ns"
puts $fp ""
puts $html "<h2>Global WNS: $g_wns ns</h2>"

# 2. IP Loop
puts $fp "--- \[SECTION 2\] SELECTED IP ANALYSIS ---"
puts $fp "IP_Name,Instance_Path,LUT_Used,LUT_Util(%),FF_Used,FF_Util(%),WNS(ns),Logic_Level"

puts $html "<table><tr><th>Standard Name</th><th>Actual Instance</th><th>LUTs</th><th>FFs</th><th>WNS</th></tr>"

# 키워드 맵을 순회하며 검색
foreach {std_name search_key} [array get target_map] {
    
    # 1. 키워드로 셀 검색 (계층 무관)
    set found_cells [get_cells -hierarchical -quiet $search_key]
    
    # 2. 가장 적절한 인스턴스 하나만 찾기 (가장 짧은 이름이 보통 Top Instance)
    set best_cell ""
    set min_len 9999
    
    foreach cell $found_cells {
        # Primitive 제외
        if {[get_property IS_PRIMITIVE $cell]} { continue }
        
        # 이름 길이 비교 (가장 짧은 것이 보통 래퍼/인스턴스 본체임)
        set len [string length $cell]
        if {$len < $min_len} {
            set min_len $len
            set best_cell $cell
        }
    }

    # 찾았으면 데이터 추출
    if {$best_cell != ""} {
        puts "Found $std_name -> $best_cell"

        # 리소스 추출
        set u_str [report_utilization -cells $best_cell -return_string -quiet]
        set u_str [string map {, ""} $u_str]
        
        set c_lut 0; set c_ff 0
        regexp {Slice LUTs\s*\|\s*(\d+)} $u_str -> c_lut
        regexp {Slice Registers\s*\|\s*(\d+)} $u_str -> c_ff
        
        set c_lut_p [format "%.2f" [expr {($c_lut * 100.0) / $TOTAL_LUT}]]
        set c_ff_p  [format "%.2f" [expr {($c_ff * 100.0) / $TOTAL_FF}]]

        # 타이밍 추출
        set p [get_timing_paths -through [get_cells $best_cell] -max_paths 1 -quiet]
        set c_wns "N/A"; set c_ll "0"
        if {$p != ""} {
            set c_wns [get_property SLACK $p]
            set c_ll [get_property LOGIC_LEVELS $p]
        }
        
        # [핵심] CSV 저장 시 'std_name'(통일된 이름)을 사용!
        puts $fp "$std_name,$best_cell,$c_lut,$c_lut_p,$c_ff,$c_ff_p,$c_wns,$c_ll"
        
        puts $html "<tr><td><b>$std_name</b></td><td>$best_cell</td><td>$c_lut</td><td>$c_ff</td><td>$c_wns</td></tr>"

    } else {
        puts "Warning: '$std_name' ($search_key) not found."
    }
}

puts $html "</table></body></html>"
close $fp
close $html
puts "-------------------------------------------------------"
puts "완료! CSV 파일: [pwd]/$output_csv"
puts "-------------------------------------------------------"
