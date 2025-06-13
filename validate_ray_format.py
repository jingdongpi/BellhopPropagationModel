#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
射线文件格式验证脚本
检查 cz.ray 文件的格式和数据正确性
"""

import sys
import os
import json
import numpy as np

# 添加项目路径
sys.path.append('/home/shunli/AcousticProjects/BellhopPropagationModel')

from python_core.readwrite import get_rays
from python_core.env import Eigenray

def validate_ray_file_format():
    """验证射线文件格式和数据的正确性"""
    
    ray_file = "data/tmp/cz.ray"
    
    if not os.path.exists(ray_file):
        print("❌ 射线文件不存在:", ray_file)
        return False
    
    print("=== 射线文件格式验证 ===")
    print(f"文件路径: {ray_file}")
    
    try:
        # 1. 手动读取文件头部信息
        with open(ray_file, 'r') as f:
            lines = f.readlines()
        
        print(f"✓ 文件总行数: {len(lines)}")
        
        # 解析文件头
        title = lines[0].strip()
        freq = float(lines[1])
        
        tmp = lines[2].split()
        tmp = [x for x in tmp if x != '']
        Nsx, Nsy, Nsz = int(tmp[0]), int(tmp[1]), int(tmp[2])
        
        tmp = lines[3].split()
        tmp = [x for x in tmp if x != '']
        Nalpha, Nbeta = int(tmp[0]), int(tmp[1])
        
        deptht = float(lines[4])
        depthb = float(lines[5])
        
        print(f"✓ 标题: {title}")
        print(f"✓ 频率: {freq} Hz")
        print(f"✓ 源位置数量: Nsx={Nsx}, Nsy={Nsy}, Nsz={Nsz}")
        print(f"✓ 射线角度数量: Nalpha={Nalpha}, Nbeta={Nbeta}")
        print(f"✓ 深度范围: {deptht} - {depthb} m")
        
        # 2. 使用 get_rays 函数读取射线数据
        print("\n=== 使用 get_rays 函数解析 ===")
        rays = get_rays(ray_file)
        
        print(f"✓ 读取成功，源数量: {len(rays)}")
        
        total_rays = 0
        for source_idx, source_rays in enumerate(rays):
            print(f"源 {source_idx}: {len(source_rays)} 条射线")
            total_rays += len(source_rays)
            
            # 检查前几条射线的详细信息
            for ray_idx, ray in enumerate(source_rays[:3]):  # 只检查前3条
                if not isinstance(ray, Eigenray):
                    print(f"❌ 射线对象类型错误: {type(ray)}")
                    continue
                
                print(f"  射线 {ray_idx}:")
                print(f"    发射角: {ray.src_ang}°")
                print(f"    上边界反射次数: {ray.num_top_bnc}")
                print(f"    下边界反射次数: {ray.num_bot_bnc}")
                print(f"    轨迹点数: {ray.xy.shape[1] if ray.xy.size > 0 else 0}")
                
                if ray.xy.size > 0:
                    if ray.xy.shape[0] != 2:
                        print(f"❌ 射线坐标维度错误: {ray.xy.shape}")
                        continue
                    
                    # 检查坐标范围
                    x_min, x_max = np.min(ray.xy[0, :]), np.max(ray.xy[0, :])
                    y_min, y_max = np.min(ray.xy[1, :]), np.max(ray.xy[1, :])
                    
                    print(f"    距离范围: {x_min:.1f} - {x_max:.1f} m")
                    print(f"    深度范围: {y_min:.1f} - {y_max:.1f} m")
                    
                    # 验证坐标数据合理性
                    if x_max > 200000:  # 距离超过200km可能有问题
                        print(f"⚠️  距离范围似乎过大: {x_max/1000:.1f} km")
                    
                    if y_max > 10000:  # 深度超过10km可能有问题
                        print(f"⚠️  深度范围似乎过大: {y_max/1000:.1f} km")
                    
                    if y_min < 0:  # 负深度
                        print(f"⚠️  出现负深度: {y_min:.1f} m")
        
        print(f"\n✓ 总射线数: {total_rays}")
        
        # 3. 验证角度范围
        print("\n=== 验证角度范围 ===")
        all_angles = []
        for source_rays in rays:
            for ray in source_rays:
                all_angles.append(ray.src_ang)
        
        if all_angles:
            min_angle = min(all_angles)
            max_angle = max(all_angles)
            print(f"✓ 发射角范围: {min_angle:.2f}° - {max_angle:.2f}°")
            
            # 检查是否符合用户指定的范围 (-90° 到 90°)
            expected_min, expected_max = -90.0, 90.0
            if abs(min_angle - expected_min) < 0.1 and abs(max_angle - expected_max) < 0.1:
                print("✓ 角度范围符合用户参数设置")
            else:
                print(f"⚠️  角度范围与用户参数不符，期望: {expected_min}° - {expected_max}°")
        
        # 4. 验证射线数量
        print("\n=== 验证射线数量 ===")
        expected_beam_number = 100  # 从用户参数中获取
        
        if total_rays == expected_beam_number:
            print(f"✓ 射线数量符合用户参数: {total_rays}")
        elif total_rays > expected_beam_number:
            print(f"ℹ️  实际射线数({total_rays})大于用户指定数量({expected_beam_number})")
            print("   这可能是因为某些角度产生了多条射线路径")
        else:
            print(f"⚠️  实际射线数({total_rays})小于用户指定数量({expected_beam_number})")
        
        return True
        
    except Exception as e:
        print(f"❌ 解析射线文件时出错: {e}")
        import traceback
        traceback.print_exc()
        return False

def check_ray_data_correspondence():
    """检查射线数据与JSON输出的对应关系"""
    
    print("\n=== 检查射线数据对应关系 ===")
    
    # 读取射线数据
    ray_file = "data/tmp/cz.ray"
    if not os.path.exists(ray_file):
        print("❌ 射线文件不存在")
        return False
    
    try:
        rays = get_rays(ray_file)
        
        # 检查第一条射线的数据
        if rays and len(rays[0]) > 0:
            first_ray = rays[0][0]
            
            print(f"第一条射线信息:")
            print(f"  发射角: {first_ray.src_ang}°")
            print(f"  坐标点数: {first_ray.xy.shape[1]}")
            
            if first_ray.xy.size > 0:
                # 打印前5个点的坐标
                print("  前5个坐标点 (距离, 深度):")
                for i in range(min(5, first_ray.xy.shape[1])):
                    x, y = first_ray.xy[0, i], first_ray.xy[1, i]
                    print(f"    点{i+1}: ({x:.2f}, {y:.2f})")
                
                # 检查坐标单位
                max_x = np.max(first_ray.xy[0, :])
                max_y = np.max(first_ray.xy[1, :])
                
                print(f"  最大距离: {max_x:.1f} m ({max_x/1000:.1f} km)")
                print(f"  最大深度: {max_y:.1f} m")
                
                # 验证单位是否正确
                if max_x > 1000 and max_x < 200000:  # 合理的距离范围 1-200km
                    print("✓ 距离单位正确 (米)")
                else:
                    print("⚠️  距离单位可能有问题")
                
                if max_y > 10 and max_y < 10000:  # 合理的深度范围 10m-10km
                    print("✓ 深度单位正确 (米)")
                else:
                    print("⚠️  深度单位可能有问题")
        
        return True
        
    except Exception as e:
        print(f"❌ 检查射线数据时出错: {e}")
        return False

if __name__ == "__main__":
    print("🔍 开始验证射线文件格式...")
    
    # 验证文件格式
    format_ok = validate_ray_file_format()
    
    # 检查数据对应关系
    data_ok = check_ray_data_correspondence()
    
    print("\n=== 验证总结 ===")
    if format_ok and data_ok:
        print("✅ 射线文件格式验证通过")
        print("✅ 数据格式正确，可以正常使用")
    else:
        print("❌ 验证过程中发现问题，需要进一步检查")
