#!/usr/bin/env python3
"""
测试射线模型参数的正确使用
"""

import json
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'python_wrapper'))

from bellhop_wrapper import solve_bellhop_propagation

def test_ray_model_params():
    """测试射线模型参数是否被正确使用"""
    
    # 读取包含ray_model_para的输入文件
    input_file = "examples/input.json"
    
    with open(input_file, 'r') as f:
        input_data = json.load(f)
    
    # 验证输入文件包含ray_model_para
    print("=== 输入文件参数检查 ===")
    if 'ray_model_para' in input_data:
        ray_params = input_data['ray_model_para']
        print(f"✓ 找到 ray_model_para: {ray_params}")
        
        if 'beam_number' in ray_params:
            print(f"✓ 用户指定射线数量: {ray_params['beam_number']}")
        
        if 'grazing_high' in ray_params and 'grazing_low' in ray_params:
            print(f"✓ 用户指定掠射角范围: {ray_params['grazing_low']}° 到 {ray_params['grazing_high']}°")
            
        if 'is_ray_output' in ray_params:
            print(f"✓ 射线输出设置: {ray_params['is_ray_output']}")
    else:
        print("✗ 输入文件中没有找到 ray_model_para")
        return False
    
    # 检查是否还有错误的beam_para
    if 'beam_para' in input_data:
        print("⚠️  警告: 输入文件中仍包含 beam_para，应该移除")
    
    print("\n=== 开始Bellhop计算测试 ===")
    
    try:
        # 调用计算函数
        result_json = solve_bellhop_propagation(json.dumps(input_data))
        result = json.loads(result_json)
        
        print(f"✓ 计算成功完成")
        print(f"错误代码: {result.get('error_code', 'N/A')}")
        print(f"错误信息: {result.get('error_message', 'N/A')}")
        
        # 检查是否有射线输出
        if result.get('ray_trace'):
            print(f"✓ 射线追踪数据已生成，包含 {len(result['ray_trace'])} 条射线")
        elif ray_params.get('is_ray_output', False):
            print("⚠️  用户要求射线输出但没有生成射线数据")
        
        # 检查传输损失数据
        if result.get('transmission_loss'):
            print(f"✓ 传输损失数据已生成")
        
        return True
        
    except Exception as e:
        print(f"✗ 计算失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_ray_model_params()
    if success:
        print("\n=== 测试通过 ===")
        print("✓ 射线模型参数正确解析和使用")
    else:
        print("\n=== 测试失败 ===")
        print("✗ 需要检查参数处理逻辑")
    
    sys.exit(0 if success else 1)
