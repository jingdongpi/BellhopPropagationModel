"""
Bellhop Python包装器
提供C++接口的Python实现
"""
import sys
import os
import json
import datetime
import numpy as np

# 添加python_core到路径
current_dir = os.path.dirname(os.path.abspath(__file__))
python_core_path = os.path.join(os.path.dirname(current_dir), 'python_core')
sys.path.insert(0, python_core_path)

# **在导入其他模块前先确保目录存在**
def ensure_data_dirs():
    """确保所有必要的数据目录存在"""
    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(current_dir)
    dirs = [
        os.path.join(project_root, 'data'),
        os.path.join(project_root, 'data', 'tmp'),
        os.path.join(project_root, 'lib'),
        os.path.join(project_root, 'examples')
    ]
    for dir_path in dirs:
        os.makedirs(dir_path, exist_ok=True)

# 初始化目录
ensure_data_dirs()

# 兼容性类定义
class Bathymetry:
    def __init__(self, r, d):
        self.r = np.array(r)
        self.d = np.array(d)

class SSPProfile:
    def __init__(self, z, c):
        self.z = np.array(z)
        self.c = np.array(c)

class Basement:
    def __init__(self, cp, cs, rho, a_p, a_s):
        self.cp = cp
        self.cs = cs
        self.rho = rho
        self.a_p = a_p
        self.a_s = a_s

def parse_input_data(input_json):
    """解析输入JSON数据 - 按照接口规范完整实现"""
    if isinstance(input_json, str):
        try:
            data = json.loads(input_json)
        except json.JSONDecodeError as e:
            raise ValueError(f"无效的JSON格式: {str(e)}")
    else:
        data = input_json
    
    # 验证输入数据不为空
    if not data:
        raise ValueError("输入数据为空")
    
    # 验证必需字段
    required_fields = ['freq', 'source_depth', 'receiver_depth', 'receiver_range', 
                      'bathy', 'sound_speed_profile', 'sediment_info']
    missing_fields = []
    for field in required_fields:
        if field not in data:
            missing_fields.append(field)
    
    if missing_fields:
        raise ValueError(f"缺少必需字段: {', '.join(missing_fields)}")
    
    # 解析频率（支持单频、多频和宽带）
    freq = data.get('freq')
    freq_range = data.get('freq_range')
    
    # 验证频率字段
    if freq is None and freq_range is None:
        raise ValueError("必须提供freq或freq_range字段")
    
    if freq is not None:
        if isinstance(freq, list):
            if not freq:  # 空列表
                raise ValueError("频率列表不能为空")
            # 支持多频率数组
            freq = [float(f) for f in freq]
            for f in freq:
                if f <= 0:
                    raise ValueError("所有频率必须大于0")
        else:
            freq = float(freq)
            if freq <= 0:
                raise ValueError("频率必须大于0")
    elif freq_range is not None:
        # 宽带模型使用中心频率
        lower = freq_range.get('lower', 100)
        upper = freq_range.get('upper', 200)
        if lower <= 0 or upper <= 0 or upper <= lower:
            raise ValueError("频率范围无效")
        freq = (lower + upper) / 2
    
    # 解析声源深度
    sd = data.get('source_depth')
    if sd is None:
        raise ValueError("缺少source_depth字段")
    
    if isinstance(sd, (list, np.ndarray)):
        if len(sd) == 0:
            raise ValueError("声源深度列表不能为空")
        sd = float(sd[0])
    else:
        sd = float(sd)
    
    if sd < 0:
        raise ValueError("声源深度不能为负数")
    
    sd = np.array([sd])  # 转换为数组格式
    
    # 解析接收器深度和距离
    rd = data.get('receiver_depth')
    if rd is None:
        raise ValueError("缺少receiver_depth字段")
    
    if not isinstance(rd, (list, np.ndarray)):
        rd = [rd]
    rd = np.array(rd)
    
    if len(rd) == 0:
        raise ValueError("接收器深度列表不能为空")
    
    if any(d < 0 for d in rd):
        raise ValueError("接收器深度不能为负数")
    
    # **新增：接收距离解析**
    receiver_range = data.get('receiver_range')
    if receiver_range is None:
        raise ValueError("缺少receiver_range字段")
    
    if not isinstance(receiver_range, (list, np.ndarray)):
        receiver_range = [receiver_range]
    receiver_range = np.array(receiver_range)
    
    if len(receiver_range) == 0:
        raise ValueError("接收器距离列表不能为空")
    
    if any(r <= 0 for r in receiver_range):
        raise ValueError("接收器距离必须大于0")
    
    # 解析测深数据
    bathy_data = data.get('bathy')
    if bathy_data is None:
        raise ValueError("缺少bathy字段")
    
    bathy_range = bathy_data.get('range')
    bathy_depth = bathy_data.get('depth')
    
    if bathy_range is None:
        raise ValueError("缺少bathy.range字段")
    if bathy_depth is None:
        raise ValueError("缺少bathy.depth字段")
    
    if not isinstance(bathy_range, (list, np.ndarray)) or len(bathy_range) == 0:
        raise ValueError("bathy.range必须是非空列表")
    if not isinstance(bathy_depth, (list, np.ndarray)) or len(bathy_depth) == 0:
        raise ValueError("bathy.depth必须是非空列表")
    
    if len(bathy_range) != len(bathy_depth):
        raise ValueError("bathy.range和bathy.depth长度必须相同")
    
    if any(r < 0 for r in bathy_range):
        raise ValueError("测深距离不能为负数")
    if any(d <= 0 for d in bathy_depth):
        raise ValueError("测深深度必须大于0")
    
    # **单位转换：用户输入的距离是米(m)，需要转换为千米(km)供内部计算使用**
    bathy_range_km = [r / 1000.0 for r in bathy_range]  # 米转千米
    # 深度保持米单位，不需要转换
    
    # 确保声速剖面深度覆盖测深范围
    max_bathy_depth = float(max(bathy_depth))
    
    # 解析声速剖面
    ssp_data = data.get('sound_speed_profile')
    if ssp_data is None:
        raise ValueError("缺少sound_speed_profile字段")
    
    if not isinstance(ssp_data, list):
        raise ValueError("sound_speed_profile必须是列表")
    
    if not ssp_data:
        # 如果为空列表，创建默认剖面
        max_depth = max_bathy_depth + 50.0
        ssp = [SSPProfile(
            z=np.array([0.0, max_depth/2.0, max_depth]), 
            c=np.array([1500.0, 1510.0, 1520.0])
        )]
    else:
        ssp = []
        for i, profile in enumerate(ssp_data):
            if not isinstance(profile, dict):
                raise ValueError(f"声速剖面[{i}]必须是字典")
            
            profile_depth = profile.get('depth')
            profile_speed = profile.get('speed')
            
            if profile_depth is None:
                raise ValueError(f"声速剖面[{i}]缺少depth字段")
            if profile_speed is None:
                raise ValueError(f"声速剖面[{i}]缺少speed字段")
            
            profile_depth = np.array(profile_depth)
            profile_speed = np.array(profile_speed)
            
            if len(profile_depth) == 0 or len(profile_speed) == 0:
                raise ValueError(f"声速剖面[{i}]的depth和speed不能为空")
            
            if len(profile_depth) != len(profile_speed):
                raise ValueError(f"声速剖面[{i}]的depth和speed长度必须相同")
            
            if any(d < 0 for d in profile_depth):
                raise ValueError(f"声速剖面[{i}]的深度不能为负数")
            if any(s <= 0 for s in profile_speed):
                raise ValueError(f"声速剖面[{i}]的速度必须大于0")
            
            if max(profile_depth) < max_bathy_depth:
                extended_depth = max_bathy_depth + 50
                extended_speed = profile_speed[-1]
                profile_depth = np.append(profile_depth, extended_depth)
                profile_speed = np.append(profile_speed, extended_speed)
            
            ssp.append(SSPProfile(z=profile_depth, c=profile_speed))
    
    bathm = Bathymetry(r=np.array(bathy_range_km), d=np.array(bathy_depth))
    
    # 解析沉积层信息
    sed = None
    
    # 解析基底参数
    sediment_info = data.get('sediment_info')
    if sediment_info is None:
        raise ValueError("缺少sediment_info字段")
    
    if not isinstance(sediment_info, list):
        raise ValueError("sediment_info必须是列表")
    
    if not sediment_info:
        # 如果为空列表，使用默认值
        base = [Basement(cp=1800, cs=200, rho=1.8, a_p=0.1, a_s=0.5)]
    else:
        if not isinstance(sediment_info[0], dict):
            raise ValueError("sediment_info[0]必须是字典")
        
        sed_data = sediment_info[0].get('sediment', {})
        base = [Basement(
            cp=sed_data.get('p_speed', 1800),
            cs=sed_data.get('s_speed', 200),
            rho=sed_data.get('density', 1.8),
            a_p=sed_data.get('p_atten', 0.1),
            a_s=sed_data.get('s_atten', 0.5)
        )]
    
    # **新增：解析其他参数**
    coherent_para = data.get('coherent_para', 'C')  # 默认相干
    is_propagation_pressure_output = data.get('is_propagation_pressure_output', False)
    
    # 解析射线模型参数 - 根据接口定义只有ray_model_para
    ray_model_para = data.get('ray_model_para', {})
    is_ray_output = ray_model_para.get('is_ray_output', False)
    beam_number = ray_model_para.get('beam_number', None)
    grazing_high = ray_model_para.get('grazing_high', None)  # 掠射角上限
    grazing_low = ray_model_para.get('grazing_low', None)    # 掠射角下限
    
    return freq, sd, rd, bathm, ssp, sed, base, {
        'coherent_para': coherent_para,
        'is_propagation_pressure_output': is_propagation_pressure_output,
        'is_ray_output': is_ray_output,
        'receiver_range': receiver_range,
        'freq_range': freq_range,
        'ray_model_para': ray_model_para,
        'beam_number': beam_number,
        'grazing_high': grazing_high,
        'grazing_low': grazing_low
    }

def format_output_data(pos, TL, freq, pressure=None, rays=None, options=None, error_code=200, error_message=""):
    """格式化输出数据 - 按照接口规范完整实现，小数精度保留2位"""
    
    # 完全避免科学计数法的JSON编码器
    class NoScientificJSONEncoder(json.JSONEncoder):
        def encode(self, obj):
            """重写encode方法，确保所有浮点数都使用固定小数点格式"""
            return self._encode_obj(obj)
        
        def _encode_obj(self, obj):
            """递归编码对象"""
            if isinstance(obj, float):
                # 浮点数格式化为固定小数点格式
                if abs(obj) < 1e-10:
                    return "0.000000"
                elif abs(obj) >= 1:
                    return f"{obj:.2f}"
                else:
                    return f"{obj:.6f}"
            elif isinstance(obj, dict):
                items = []
                for k, v in obj.items():
                    key_str = json.dumps(k)
                    val_str = self._encode_obj(v)
                    items.append(f"{key_str}: {val_str}")
                return "{" + ", ".join(items) + "}"
            elif isinstance(obj, (list, tuple)):
                items = [self._encode_obj(item) for item in obj]
                return "[" + ", ".join(items) + "]"
            elif isinstance(obj, str):
                # 字符串直接使用json.dumps处理
                return json.dumps(obj)
            else:
                # 其他类型（int, bool, None等）使用默认处理
                return json.dumps(obj)
    
    if error_code != 200:
        return json.dumps({
            'error_code': error_code,
            'error_message': error_message,
            'receiver_depth': [],
            'receiver_range': [],
            'transmission_loss': [],
            'propagation_pressure': [],
            'ray_trace': [],
            'time_wave': {}
        }, cls=NoScientificJSONEncoder)
    
    # 辅助函数：将数值转换为保留2位小数的浮点数
    def round_to_2_decimals(value):
        if isinstance(value, (int, float)):
            return round(float(value), 2)
        return value
    
    def process_array_to_2_decimals(arr):
        """递归处理多维数组，确保所有数值都保留2位小数"""
        if isinstance(arr, (int, float)):
            return round_to_2_decimals(arr)
        elif isinstance(arr, (list, tuple)):
            return [process_array_to_2_decimals(item) for item in arr]
        elif isinstance(arr, np.ndarray):
            return [process_array_to_2_decimals(item) for item in arr.tolist()]
        else:
            return arr
    
    # 基本输出
    result = {
        'error_code': 200,
        'error_message': '',
        'receiver_depth': [round_to_2_decimals(d) for d in pos.r.depth.tolist()] if hasattr(pos.r, 'depth') else [],
        # **Debug: Check what pos.r.range actually contains**
        'receiver_range': [round_to_2_decimals(r) for r in pos.r.range.tolist()] if hasattr(pos.r, 'range') else [],
        'transmission_loss': process_array_to_2_decimals(TL.tolist()) if isinstance(TL, np.ndarray) else []
    }
    
    # 处理多频率输出格式
    if isinstance(freq, list) and len(freq) > 1:
        # 多频率输出：添加频率信息
        result['frequencies'] = [round_to_2_decimals(f) for f in freq]
        result['is_multi_frequency'] = True
        
        # 传输损失格式：[freq_idx][depth_idx][range_idx]
        if isinstance(TL, np.ndarray) and TL.ndim == 3:
            # 多频率TL数据：[Nfreq, Ndepth, Nrange]
            result['transmission_loss'] = process_array_to_2_decimals(TL.tolist())
        elif isinstance(TL, np.ndarray) and TL.ndim == 2:
            # 单频率格式，扩展为多频率格式
            result['transmission_loss'] = [process_array_to_2_decimals(TL.tolist())]
    else:
        # 单频率输出
        result['frequencies'] = [round_to_2_decimals(freq if not isinstance(freq, list) else freq[0])]
        result['is_multi_frequency'] = False
        
        # 确保单频率TL格式正确
        if isinstance(TL, np.ndarray) and TL.ndim == 3:
            # 多频率数据但只有一个频率，取第一个
            result['transmission_loss'] = process_array_to_2_decimals(TL[0].tolist())
        elif isinstance(TL, np.ndarray):
            result['transmission_loss'] = process_array_to_2_decimals(TL.tolist())
    
    # 可选输出：声压
    if options and options.get('is_propagation_pressure_output', False) and pressure is not None:
        pressure_data = []
        if isinstance(pressure, np.ndarray):
            # 处理不同维度的压力数据
            if pressure.ndim == 2:
                # 2D数组：单频率压力数据 [depth, range]
                for i in range(pressure.shape[0]):
                    row = []
                    for j in range(pressure.shape[1]):
                        row.append({
                            'real': pressure[i, j].real,
                            'imag': pressure[i, j].imag
                        })
                    pressure_data.append(row)
            elif pressure.ndim == 3:
                # 3D数组：多频率压力数据 [freq, depth, range]
                if isinstance(freq, list) and len(freq) > 1:
                    # 多频率格式：返回每个频率的压力数据
                    pressure_data = []
                    for f_idx in range(pressure.shape[0]):
                        freq_pressure = []
                        for i in range(pressure.shape[1]):
                            row = []
                            for j in range(pressure.shape[2]):
                                row.append({
                                    'real': pressure[f_idx, i, j].real,
                                    'imag': pressure[f_idx, i, j].imag
                                })
                            freq_pressure.append(row)
                        pressure_data.append(freq_pressure)
                else:
                    # 单频率情况：取第一个频率
                    for i in range(pressure.shape[1]):
                        row = []
                        for j in range(pressure.shape[2]):
                            row.append({
                                'real': pressure[0, i, j].real,
                                'imag': pressure[0, i, j].imag
                            })
                        pressure_data.append(row)
            elif pressure.ndim == 4:
                # 4D数组：取第一个频率和第一个声源位置
                p_2d = pressure[0, 0, :, :] if pressure.shape[0] > 0 and pressure.shape[1] > 0 else pressure.reshape(pressure.shape[-2], pressure.shape[-1])
                for i in range(p_2d.shape[0]):
                    row = []
                    for j in range(p_2d.shape[1]):
                        row.append({
                            'real': p_2d[i, j].real,
                            'imag': p_2d[i, j].imag
                        })
                    pressure_data.append(row)
            else:
                # 其他情况：展平为2D
                p_flat = pressure.reshape(-1, pressure.shape[-1]) if pressure.ndim > 2 else pressure
                for i in range(min(p_flat.shape[0], 100)):  # 限制最大行数
                    row = []
                    for j in range(p_flat.shape[1]):
                        row.append({
                            'real': p_flat[i, j].real,
                            'imag': p_flat[i, j].imag
                        })
                    pressure_data.append(row)
        result['propagation_pressure'] = pressure_data
    else:
        result['propagation_pressure'] = []
    
    # 可选输出：射线轨迹
    if options and options.get('is_ray_output', False) and rays is not None:
        ray_trace_data = []
        if rays:
            # rays 是一个射线列表（来自 find_cvgcRays 函数的返回值）
            # 需要直接遍历射线，而不是期望嵌套结构
            for ray in rays:  # 直接遍历射线列表
                # 从射线对象中提取数据，注意属性名称
                launch_angle = getattr(ray, 'src_ang', getattr(ray, 'alpha', 0))  # 发射角度
                ray_xy = getattr(ray, 'xy', np.array([[], []]))  # 射线轨迹坐标
                
                # 调试：检查射线数据的原始值
                if ray_xy.size > 0 and ray_xy.shape[0] >= 2:
                    print(f"Debug: ray_xy shape: {ray_xy.shape}")
                    print(f"Debug: ray_xy[0] (range) sample: {ray_xy[0, :5] if ray_xy.shape[1] > 5 else ray_xy[0, :]}")
                    print(f"Debug: ray_xy[1] (depth) sample: {ray_xy[1, :5] if ray_xy.shape[1] > 5 else ray_xy[1, :]}")
                    print(f"Debug: max depth in ray: {np.max(ray_xy[1, :])}")
                    print(f"Debug: min depth in ray: {np.min(ray_xy[1, :])}")
                
                # 转换坐标单位和精度：距离和深度都保持m（整数）
                if ray_xy.size > 0 and ray_xy.shape[0] >= 2:
                    ray_range_m_data = ray_xy[0, :]  # 距离（米）
                    ray_depth_m = ray_xy[1, :]       # 深度（米）
                    
                    # 转换为整数
                    ray_range_m = [int(round(r)) for r in ray_range_m_data]  # 距离转为整数（不需要乘1000）
                    ray_depth_m_int = [int(round(d)) for d in ray_depth_m]   # 深度转为整数
                    
                    ray_info = {
                        'alpha': round_to_2_decimals(launch_angle),
                        'num_top_bnc': int(getattr(ray, 'num_top_bnc', 0)),
                        'num_bot_bnc': int(getattr(ray, 'num_bot_bnc', 0)),
                        'ray_range': ray_range_m,
                        'ray_depth': ray_depth_m_int
                    }
                    ray_trace_data.append(ray_info)
        result['ray_trace'] = ray_trace_data
    else:
        result['ray_trace'] = []
    
    # 时域波形（暂不实现）
    result['time_wave'] = {}
    
    return json.dumps(result, cls=NoScientificJSONEncoder)

def solve_bellhop_propagation(input_json):
    """
    Bellhop声传播计算的主要接口函数 - 符合完整接口规范
    """
    import os  # 确保os模块在函数开始就导入
    try:
        # 确保目录存在
        project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        dirs = [
            os.path.join(project_root, 'data'),
            os.path.join(project_root, 'data', 'tmp'),
            os.path.join(project_root, 'lib'),
            os.path.join(project_root, 'examples')
        ]
        for dir_path in dirs:
            os.makedirs(dir_path, exist_ok=True)
        
        # 动态导入，避免初始化时的依赖问题
        try:
            # 尝试直接导入
            import python_core.bellhop as bellhop_module
            bellhop = bellhop_module
        except ImportError:
            # 如果导入失败，确保路径正确后再导入
            if python_core_path not in sys.path:
                sys.path.insert(0, python_core_path)
            import python_core.bellhop as bellhop_module
            bellhop = bellhop_module
        
        call_Bellhop = bellhop.call_Bellhop
        call_Bellhop_Rays = bellhop.call_Bellhop_Rays
        call_Bellhop_multi_freq = bellhop.call_Bellhop_multi_freq
        
        # 解析输入参数（更新后的函数）
        freq, sd, rd, bathm, ssp, sed, base, options = parse_input_data(input_json)
        
        # 从options中提取射线参数
        receiver_range = options.get('receiver_range', [])
        beam_number = options.get('beam_number')
        grazing_high = options.get('grazing_high')
        grazing_low = options.get('grazing_low')
        
        pressure = None
        rays = None
        
        # 统一处理：将单个频率转换为列表格式，这样可以统一使用 multi_freq 函数
        if not isinstance(freq, list):
            freq = [freq]  # 单个频率转换为单元素列表
        
        # 检测是否为多频率输入（用于输出格式判断）
        is_multi_freq = len(freq) > 1
        
        # 根据选项决定计算类型
        if options.get('is_ray_output', False):
            # 射线追踪计算 - 目前射线追踪不支持多频率，使用第一个频率
            ray_freq = freq[0]
            try:
                # 计算射线轨迹 - 传递射线参数
                rays_total = call_Bellhop_Rays(ray_freq, sd, rd, receiver_range, bathm, ssp, sed, base,
                                             beam_number=beam_number, grazing_high=grazing_high, grazing_low=grazing_low)
                
                # 导入射线筛选函数
                from python_core.bellhop import find_cvgcRays
                
                # 筛选收敛射线，传递海底深度信息
                rays = find_cvgcRays(rays_total, bathm)
                
                print(f"Ray tracing completed, receiver depth points: {len(rd)}, max range: {bathm.r[-1]*1000:.0f}m")
            except Exception as e:
                print(f"Ray tracing calculation failed: {str(e)}")
                rays = []  # 如果失败，返回空列表
            
            # 同时计算传输损失 - 统一使用 multi_freq 函数
            if options.get('is_propagation_pressure_output', False):
                pos, TL, pressure = call_Bellhop_multi_freq(freq, sd, rd, receiver_range, bathm, ssp, sed, base, 
                                                           return_pressure=True, performance_mode=False,
                                                           beam_number=beam_number, grazing_high=grazing_high, grazing_low=grazing_low)
            else:
                pos, TL = call_Bellhop_multi_freq(freq, sd, rd, receiver_range, bathm, ssp, sed, base, 
                                                 return_pressure=False, performance_mode=False,
                                                 beam_number=beam_number, grazing_high=grazing_high, grazing_low=grazing_low)
        else:
            # 只计算传输损失 - 统一使用 multi_freq 函数
            if options.get('is_propagation_pressure_output', False):
                pos, TL, pressure = call_Bellhop_multi_freq(freq, sd, rd, receiver_range, bathm, ssp, sed, base, 
                                                           return_pressure=True, performance_mode=False,
                                                           beam_number=beam_number, grazing_high=grazing_high, grazing_low=grazing_low)
            else:
                pos, TL = call_Bellhop_multi_freq(freq, sd, rd, receiver_range, bathm, ssp, sed, base, 
                                                 return_pressure=False, performance_mode=False,
                                                 beam_number=beam_number, grazing_high=grazing_high, grazing_low=grazing_low)
        
        # 格式化输出
        return format_output_data(pos, TL, freq, pressure, rays, options)
        
    except Exception as e:
        import traceback
        # 获取详细的错误信息
        error_detail = traceback.format_exc()
        error_msg = f"Bellhop calculation failed: {str(e)}\nDetailed error info:\n{error_detail}"
        
        # 记录到文件以便调试
        try:
            import os
            log_file = os.path.join(os.path.dirname(__file__), '..', 'data', 'error_log.txt')
            os.makedirs(os.path.dirname(log_file), exist_ok=True)
            with open(log_file, 'a', encoding='utf-8') as f:
                import datetime
                f.write(f"\n=== {datetime.datetime.now()} ===\n")
                f.write(f"Input data: {input_json[:500]}...\n")
                f.write(f"Error message: {error_msg}\n")
        except:
            pass  # 如果日志记录失败，不影响主流程
            
        return format_output_data(None, None, 0, error_code=500, error_message=error_msg)