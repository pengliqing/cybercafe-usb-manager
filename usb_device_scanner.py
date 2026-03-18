#!/usr/bin/env python3
"""
USB设备扫描器 - 使用WMI查询Windows USB设备信息
适用于Windows 10系统

需要安装：pip install wmi
"""

import wmi
import re

class USBDeviceScanner:
    """USB设备扫描器类"""
    
    def __init__(self):
        """初始化WMI连接"""
        try:
            self.c = wmi.WMI()
            print("WMI连接成功")
        except Exception as e:
            print(f"WMI连接失败: {e}")
            raise
    
    def get_all_usb_devices(self):
        """获取所有USB设备"""
        devices = []
        
        try:
            # 查询所有PnP设备
            for device in self.c.Win32_PnPEntity(ConfigManagerErrorCode=0):
                # 检查是否是USB设备
                if self._is_usb_device(device):
                    device_info = self._parse_device_info(device)
                    if device_info:
                        devices.append(device_info)
                        
        except Exception as e:
            print(f"查询设备失败: {e}")
            
        return devices
    
    def get_keyboard_mouse_devices(self):
        """获取键盘鼠标设备"""
        keyboards = []
        mice = []
        
        all_devices = self.get_all_usb_devices()
        
        for device in all_devices:
            desc = device.get('description', '').lower()
            name = device.get('name', '').lower()
            
            # 中文和英文关键词匹配
            keyboard_keywords = ['键盘', 'keyboard']
            mouse_keywords = ['鼠标', 'mouse', 'rat', 'deathadder', 'g502']
            
            is_keyboard = any(keyword in desc or keyword in name 
                            for keyword in keyboard_keywords)
            is_mouse = any(keyword in desc or keyword in name 
                          for keyword in mouse_keywords)
            
            if is_keyboard:
                device['type'] = '键盘'
                keyboards.append(device)
            elif is_mouse:
                device['type'] = '鼠标'
                mice.append(device)
        
        return keyboards, mice
    
    def _is_usb_device(self, device):
        """判断是否为USB设备"""
        if not device.DeviceID:
            return False
        
        # USB设备ID通常包含USB\VID_或HID\VID_
        device_id = device.DeviceID.upper()
        return 'USB' in device_id or 'HID' in device_id
    
    def _parse_device_info(self, device):
        """解析设备信息"""
        if not device.DeviceID:
            return None
        
        info = {
            'name': device.Name or '',
            'description': device.Description or '',
            'device_id': device.DeviceID or '',
            'manufacturer': device.Manufacturer or '',
            'status': '正常' if device.Status == 'OK' else device.Status,
            'vid': '',
            'pid': '',
            'vendor_name': '',
            'product_name': ''
        }
        
        # 提取VID和PID
        vid_pid_match = re.search(r'VID_([0-9A-F]{4})&PID_([0-9A-F]{4})', 
                                 device.DeviceID.upper())
        if vid_pid_match:
            info['vid'] = vid_pid_match.group(1)
            info['pid'] = vid_pid_match.group(2)
        
        return info
    
    def _lookup_vendor_name(self, vid):
        """根据VID查找厂商名称（简化版）"""
        # 常见游戏外设厂商VID
        vendor_db = {
            '045E': 'Microsoft',        # 微软
            '046D': 'Logitech',         # 罗技
            '1532': 'Razer',            # 雷蛇
            '1038': 'SteelSeries',      # 赛睿
            '1B1C': 'Corsair',          # 海盗船
            '0951': 'Kingston',         # 金士顿
            '0B05': 'ASUS',             # 华硕
            '1EA7': 'Roccat',           # 冰豹
            '046A': 'Cherry',           # 樱桃
            '04D9': 'Qisan',            # 琦梵
        }
        
        return vendor_db.get(vid.upper(), '未知厂商')
    
    def print_device_info(self, device):
        """打印设备信息"""
        print(f"设备类型: {device.get('type', '未知')}")
        print(f"名称: {device.get('name', '未知')}")
        print(f"描述: {device.get('description', '未知')}")
        print(f"制造商: {device.get('manufacturer', '未知')}")
        print(f"设备ID: {device.get('device_id', '未知')}")
        
        vid = device.get('vid')
        pid = device.get('pid')
        if vid and pid:
            vendor_name = self._lookup_vendor_name(vid)
            print(f"VID: {vid} ({vendor_name})")
            print(f"PID: {pid}")
        
        print(f"状态: {device.get('status', '未知')}")
        print("-" * 50)


def main():
    """主函数"""
    print("网吧USB设备扫描器 v0.1")
    print("=" * 50)
    
    try:
        scanner = USBDeviceScanner()
        
        # 获取所有USB设备
        all_devices = scanner.get_all_usb_devices()
        print(f"找到 {len(all_devices)} 个USB设备")
        
        # 获取键盘鼠标设备
        keyboards, mice = scanner.get_keyboard_mouse_devices()
        
        print(f"\n找到 {len(keyboards)} 个键盘:")
        for idx, kb in enumerate(keyboards, 1):
            print(f"\n键盘 {idx}:")
            scanner.print_device_info(kb)
        
        print(f"\n找到 {len(mice)} 个鼠标:")
        for idx, mouse in enumerate(mice, 1):
            print(f"\n鼠标 {idx}:")
            scanner.print_device_info(mouse)
        
        # 统计信息
        print("\n统计信息:")
        print(f"总USB设备数: {len(all_devices)}")
        print(f"键盘数: {len(keyboards)}")
        print(f"鼠标数: {len(mice)}")
        
        # 建议的品牌程序
        print("\n建议启动的品牌程序:")
        brands = set()
        for device in keyboards + mice:
            vid = device.get('vid')
            if vid:
                vendor = scanner._lookup_vendor_name(vid)
                if vendor != '未知厂商':
                    brands.add(vendor)
        
        brand_programs = {
            'Razer': '雷蛇 Synapse',
            'Logitech': '罗技 G Hub',
            'SteelSeries': '赛睿 Engine',
            'Corsair': '海盗船 iCUE',
            'ASUS': '华硕 Armoury Crate'
        }
        
        for brand in brands:
            if brand in brand_programs:
                print(f"- {brand}: {brand_programs[brand]}")
            else:
                print(f"- {brand}: 需要配套软件")
                
    except Exception as e:
        print(f"程序执行出错: {e}")


if __name__ == "__main__":
    main()