#!/usr/bin/env python3
"""
测试重新生成中等数据量文件，验证格式化和射线追踪
"""
import sys
import os
import json

# 添加路径
sys.path.append('python_wrapper')
from bellhop_wrapper import solve_bellhop_propagation

def test_medium_with_rays():
    """测试中等数据量，包含射线追踪"""
    
    # 读取输入文件
    input_file = 'examples/input_medium.json'
    try:
        with open(input_file, 'r') as f:
            input_data = json.load(f)
    except FileNotFoundError:
        print(f"❌ 找不到输入文件: {input_file}")
        return
    
    print("🧪 测试中等数据量计算（包含射线追踪）...")
    print(f"输入文件: {input_file}")
    
    # 添加射线追踪和压力输出选项
    input_data['is_propagation_pressure_output'] = True
    input_data['ray_model_para'] = {
        'is_ray_output': True
    }
    
    print(f"接收深度数量: {len(input_data['receiver_depth'])}")
    print(f"接收距离数量: {len(input_data['receiver_range'])}")
    print(f"总计算点数: {len(input_data['receiver_depth']) * len(input_data['receiver_range'])}")
    print(f"射线追踪: 启用")
    print(f"压力输出: 启用")
    
    try:
        result = solve_bellhop_propagation(json.dumps(input_data))
        result_data = json.loads(result)
        
        if result_data.get('error_code') == 200:
            print("✅ 计算成功!")
            
            # 检查距离单位
            output_ranges = result_data.get('receiver_range', [])
            if output_ranges:
                print(f"输出距离示例: {output_ranges[:3]}...")
                # 验证距离单位是否合理
                expected_first = input_data['receiver_range'][0]
                actual_first = output_ranges[0]
                if abs(actual_first - expected_first) < 1.0:
                    print("✅ 距离单位正确")
                else:
                    print(f"❌ 距离单位可能错误: 期望≈{expected_first}, 实际={actual_first}")
            
            # 检查压力数据格式
            pressure_data = result_data.get('propagation_pressure', [])
            if pressure_data:
                print("✅ 压力数据存在")
                # 检查第一个非空行的第一个压力值
                for row in pressure_data:
                    if row:  # 找到第一个非空行
                        first_pressure = row[0]
                        real_val = first_pressure.get('real', 0)
                        imag_val = first_pressure.get('imag', 0)
                        
                        print(f"压力示例: real={real_val}, imag={imag_val}")
                        
                        # 检查是否包含科学计数法
                        real_str = str(real_val)
                        imag_str = str(imag_val)
                        
                        if 'e' in real_str.lower() or 'e' in imag_str.lower():
                            print(f"❌ 仍包含科学计数法: real={real_str}, imag={imag_str}")
                        else:
                            print("✅ 压力格式正确: 固定小数格式")
                        break
            else:
                print("❌ 压力数据为空")
            
            # 检查射线追踪数据
            ray_data = result_data.get('ray_trace', [])
            if ray_data:
                print(f"✅ 射线数据存在: {len(ray_data)} 条射线")
                
                # 检查射线数据内容
                non_empty_rays = 0
                for ray in ray_data:
                    ray_range = ray.get('ray_range', [])
                    ray_depth = ray.get('ray_depth', [])
                    if ray_range and ray_depth:
                        non_empty_rays += 1
                
                if non_empty_rays > 0:
                    print(f"✅ 有效射线数据: {non_empty_rays} 条射线包含轨迹数据")
                    
                    # 显示第一条有效射线的信息
                    for ray in ray_data:
                        ray_range = ray.get('ray_range', [])
                        ray_depth = ray.get('ray_depth', [])
                        if ray_range and ray_depth:
                            print(f"  示例射线: alpha={ray.get('alpha', 'N/A')}, "
                                  f"轨迹点数={len(ray_range)}, "
                                  f"距离范围={min(ray_range):.1f}-{max(ray_range):.1f}m")
                            break
                else:
                    print("❌ 所有射线数据都为空")
                    print("   可能原因：")
                    print("   1. 射线追踪参数设置不当")
                    print("   2. 环境参数不支持射线传播")
                    print("   3. 射线追踪计算失败")
            else:
                print("❌ 射线数据为空")
            
            # 保存输出文件
            output_file = 'examples/output_input_medium_new.json'
            with open(output_file, 'w') as f:
                json.dump(result_data, f, indent=2)
            print(f"✅ 结果已保存到: {output_file}")
            
        else:
            print(f"❌ 计算失败: {result_data.get('error_message', '未知错误')}")
            
    except Exception as e:
        print(f"❌ 测试异常: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_medium_with_rays()
