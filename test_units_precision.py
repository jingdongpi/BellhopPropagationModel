#!/usr/bin/env python3
"""
测试距离单位和数值精度修复
"""
import sys
import os
import json

# 添加路径
sys.path.append('python_wrapper')
from bellhop_wrapper import solve_bellhop_propagation

def test_units_and_precision():
    """测试距离单位和数值精度"""
    
    # 创建一个最小的测试数据
    test_input = {
        "freq": [100],
        "source_depth": [50],
        "receiver_depth": [10, 20],
        "receiver_range": [1000, 2000],  # 输入是米
        "bathy": {
            "range": [0, 5000],
            "depth": [100, 100]
        },
        "sound_speed_profile": [
            {
                "depth": [0, 100, 200],
                "speed": [1500, 1510, 1520]
            }
        ],
        "sediment_info": [],
        "is_propagation_pressure_output": True
    }
    
    print("🧪 测试距离单位和数值精度...")
    print(f"输入距离: {test_input['receiver_range']} 米")
    
    try:
        result = solve_bellhop_propagation(json.dumps(test_input))
        result_data = json.loads(result)
        
        if result_data.get('error_code') == 200:
            print("✅ 计算成功!")
            
            # 检查距离输出
            output_ranges = result_data.get('receiver_range', [])
            print(f"输出距离: {output_ranges} 米")
            
            # 验证距离是否正确
            expected_ranges = [1000.0, 2000.0]
            if output_ranges == expected_ranges:
                print("✅ 距离单位正确!")
            else:
                print(f"❌ 距离单位错误! 期望: {expected_ranges}, 实际: {output_ranges}")
            
            # 检查传输损失精度
            tl_data = result_data.get('transmission_loss', [])
            if tl_data:
                print("✅ 传输损失数据存在")
                # 检查第一个数值的精度
                first_value = tl_data[0][0][0][0] if len(tl_data) > 0 and len(tl_data[0]) > 0 and len(tl_data[0][0]) > 0 and len(tl_data[0][0][0]) > 0 else None
                if first_value is not None:
                    # 检查是否为2位小数
                    decimal_places = len(str(first_value).split('.')[-1]) if '.' in str(first_value) else 0
                    print(f"传输损失示例值: {first_value} (小数位数: {decimal_places})")
                    if decimal_places <= 2:
                        print("✅ 传输损失精度正确 (≤2位小数)")
                    else:
                        print(f"❌ 传输损失精度错误 ({decimal_places}位小数)")
            
            # 检查压力数据精度
            pressure_data = result_data.get('propagation_pressure', [])
            if pressure_data:
                print("✅ 压力数据存在")
                first_pressure = pressure_data[0][0] if len(pressure_data) > 0 and len(pressure_data[0]) > 0 else None
                if first_pressure:
                    real_val = first_pressure.get('real', 0)
                    imag_val = first_pressure.get('imag', 0)
                    
                    # 检查精度
                    real_decimals = len(str(real_val).split('.')[-1]) if '.' in str(real_val) else 0
                    imag_decimals = len(str(imag_val).split('.')[-1]) if '.' in str(imag_val) else 0
                    
                    print(f"压力示例值: real={real_val} (小数位数: {real_decimals}), imag={imag_val} (小数位数: {imag_decimals})")
                    if real_decimals <= 6 and imag_decimals <= 6:
                        print("✅ 压力数据精度正确 (≤6位小数)")
                    else:
                        print(f"❌ 压力数据精度可能过高")
                        
        else:
            print(f"❌ 计算失败: {result_data.get('error_message', '未知错误')}")
            
    except Exception as e:
        print(f"❌ 测试异常: {str(e)}")

if __name__ == "__main__":
    test_units_and_precision()
