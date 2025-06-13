#!/usr/bin/env python3
"""
调试距离单位处理
"""
import sys
import os
import json
import numpy as np

# 添加路径
sys.path.append('python_wrapper')
sys.path.append('python_core')

from bellhop_wrapper import solve_bellhop_propagation

def debug_distance_units():
    """调试距离单位处理过程"""
    
    test_input = {
        "freq": [100],
        "source_depth": [50],
        "receiver_depth": [10, 20],
        "receiver_range": [1000, 2000],  # 输入：米
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
        "sediment_info": []
    }
    
    print("🔍 调试距离单位处理...")
    print(f"1. 输入距离（米）: {test_input['receiver_range']}")
    
    # 手动模拟处理过程
    receiver_ranges = np.array(test_input['receiver_range'])  # [1000, 2000] 米
    print(f"2. 接收器距离数组（米）: {receiver_ranges}")
    
    # Bellhop内部转换
    ran_km = receiver_ranges / 1000.0  # [1.0, 2.0] 千米
    print(f"3. 转换为千米供Bellhop内部使用: {ran_km}")
    
    # 模拟Dom类处理
    from env import Dom
    dom = Dom(ran_km, [10, 20])
    print(f"4. Dom.range（千米）: {dom.range}")
    
    # 输出转换
    output_meters = dom.range * 1000  # 应该是 [1000, 2000] 米
    print(f"5. 转换回米用于输出: {output_meters}")
    
    print("\n🧪 运行实际测试...")
    try:
        result = solve_bellhop_propagation(json.dumps(test_input))
        result_data = json.loads(result)
        
        if result_data.get('error_code') == 200:
            output_ranges = result_data.get('receiver_range', [])
            print(f"6. 实际输出距离（米）: {output_ranges}")
            
            expected = [1000.0, 2000.0]
            if output_ranges == expected:
                print("✅ 距离处理正确!")
            else:
                print(f"❌ 距离处理错误!")
                print(f"   期望: {expected}")
                print(f"   实际: {output_ranges}")
                
                # 计算倍数关系
                if output_ranges and expected:
                    ratio = output_ranges[0] / expected[0]
                    print(f"   倍数关系: {ratio}x")
        else:
            print(f"❌ 计算失败: {result_data.get('error_message', '未知错误')}")
            
    except Exception as e:
        print(f"❌ 测试异常: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    debug_distance_units()
