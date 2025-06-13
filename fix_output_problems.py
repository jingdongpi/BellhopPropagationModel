#!/usr/bin/env python3
"""
修复Bellhop输出问题的脚本
"""
import json
import re

def fix_scientific_notation_in_file(input_file, output_file):
    """修复文件中的科学计数法"""
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 使用正则表达式替换科学计数法
    def replace_scientific(match):
        value = float(match.group(0))
        return f'"{value:.6f}"'
    
    # 匹配科学计数法模式
    pattern = r'-?\d+\.?\d*e[+-]\d+'
    fixed_content = re.sub(pattern, replace_scientific, content)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    
    print(f"科学计数法修复完成: {input_file} -> {output_file}")

def regenerate_output_with_fixes():
    """重新生成输出文件并应用所有修复"""
    import sys
    import os
    
    # 添加路径
    sys.path.insert(0, '/home/shunli/AcousticProjects/BellhopPropagationModel/python_wrapper')
    
    from bellhop_wrapper import solve_bellhop_propagation
    
    input_files = [
        '/home/shunli/AcousticProjects/BellhopPropagationModel/examples/input_medium.json'
    ]
    
    for input_file in input_files:
        if os.path.exists(input_file):
            with open(input_file, 'r', encoding='utf-8') as f:
                input_data = f.read()
            
            # 重新计算
            result = solve_bellhop_propagation(input_data)
            
            # 保存修复后的结果
            base_name = os.path.splitext(os.path.basename(input_file))[0]
            output_file = f'/home/shunli/AcousticProjects/BellhopPropagationModel/examples/output_{base_name}_fixed.json'
            
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(result)
            
            print(f"重新生成: {output_file}")

if __name__ == "__main__":
    regenerate_output_with_fixes()
