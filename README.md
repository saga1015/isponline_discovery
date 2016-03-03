# port_isponline_discovery
根据指定端口统计ISP运营商信息并在zabbix里展示

1. 在zabbix某台Host或者Template中，新建Discovery rules，Key值填写"isponline_discovery[10000]"或"isponline_discovery["1000[1-9]"]"，支持正则表达式；
2. 在Item里分别添加"DX(电信),LT(联通),YD(移动),TT(铁通),JYW(教育网),CCKD(长城宽带),HW(海外)"的item项，Key值分别为，如电信："isponline_count[DX]"；
3. 在Graphs里添加以上ISP运营商的Item项，集中展示图表；
