"""
Bellhop配置文件
"""
import os
from pathlib import Path

# 项目根目录和二进制文件路径
PROJECT_ROOT = Path(__file__).parent.parent
BUILTIN_BIN_DIR = PROJECT_ROOT / "bin"

def get_binary_path():
    """获取二进制文件路径，使用项目bin目录"""
    return str(BUILTIN_BIN_DIR)

# 设置二进制文件路径 - 固定使用项目bin目录
AtBinPath = get_binary_path()

# 检查bellhop二进制文件是否存在
def check_bellhop_binary():
    """检查bellhop二进制文件是否存在"""
    bellhop_path = BUILTIN_BIN_DIR / "bellhop"
    if not bellhop_path.exists():
        print(f"⚠️  Warning: bellhop binary not found at {bellhop_path}")
        print("   Please place the bellhop binary file in the project's bin/ directory")
        return False
    return True

# 在模块加载时检查二进制文件
if not check_bellhop_binary():
    print(f"   Expected path: {BUILTIN_BIN_DIR / 'bellhop'}")
else:
    print(f"✓ Found bellhop binary at: {BUILTIN_BIN_DIR / 'bellhop'}")

# 工作目录配置 - 使用统一的项目管理
try:
    from .project import ensure_project_dirs, get_project_root, get_data_path, get_tmp_path
    ensure_project_dirs()
    WORK_DIR = str(Path(__file__).parent)
    DATA_DIR = get_data_path()
    TMP_DIR = get_tmp_path()
except ImportError:
    # 备用方案
    from pathlib import Path
    WORK_DIR = str(Path(__file__).parent)
    DATA_DIR = str(Path(__file__).parent.parent / "data")
    TMP_DIR = str(Path(__file__).parent.parent / "data" / "tmp")
    Path(TMP_DIR).mkdir(parents=True, exist_ok=True)

try:
    # 尝试相对导入 (用于包模式)
    from .readwrite import write_env, read_shd, get_rays
    from .env import Pos, Source, Dom, cInt, SSPraw, SSP, HS, BotBndry, TopBndry, Bndry, Box, Beam
except ImportError:
    # 尝试绝对导入 (用于直接脚本模式)
    from readwrite import write_env, read_shd, get_rays
    from env import Pos, Source, Dom, cInt, SSPraw, SSP, HS, BotBndry, TopBndry, Bndry, Box, Beam

from os import system
import numpy as np
from multiprocessing import Pool
from scipy.stats import norm
import math
import os  # Add this import
import warnings


# 新增多频率批量处理函数
def call_Bellhop_multi_freq(frequencies, source_depth, receiver_depths, receiver_ranges, 
                           bathymetry, sound_speed_profile, sediment, bottom_params,
                           return_pressure=False, performance_mode=False, 
                           beam_number=None, grazing_high=None, grazing_low=None):
    """
    Multi-frequency Bellhop calculation function
    
    Args:
        frequencies: array of frequencies (Hz)
        source_depth: source depth (m) 
        receiver_depths: receiver depth array (m)
        receiver_ranges: receiver range array (m)
        bathymetry: bathymetry data
        sound_speed_profile: sound speed profile
        sediment: sediment layer data
        bottom_params: bottom parameters
        return_pressure: whether to return pressure data
        performance_mode: performance mode flag
        beam_number: user-specified beam number
        grazing_high: upper grazing angle limit (degrees)
        grazing_low: lower grazing angle limit (degrees)
    
    Returns:
        (Pos1, TL_multi, pressure_multi) where TL_multi and pressure_multi have frequency dimension
    """    # 确保频率是数组
    if not isinstance(frequencies, (list, np.ndarray)):
        frequencies = [frequencies]
    frequencies = np.array(frequencies)
    Nfreq = len(frequencies)
    
    # Source and receiving position setup (similar to WGNPd implementation)
    filename = 'data/tmp/multi_freq'
    
    # **确保目录存在**
    os.makedirs('data/tmp', exist_ok=True)
    
    # Convert units for Bellhop
    ran = np.array(receiver_ranges) / 1000.0  # Convert to km
    RD = np.array(receiver_depths)  # Keep in meters
    Rmax = max(ran)
    
    print(f"Using user-defined grid: {len(receiver_ranges)} range points, {len(RD)} depth points")
    
    # Calculate sound speed profile related parameters
    NZmax, Zmax, ssp_idx = calZmax(sound_speed_profile)
    
    pos = Pos(Source(source_depth), Dom(ran, RD))
    
    # Range of phase velocity
    cint_obj = cInt(1400, 15000)

    # The number of media
    NMedia = 1
    ssp_raw = []
    depth = [0]
    
    # Sound speed profile setup (same as single frequency)
    Z_original = sound_speed_profile[ssp_idx].z
    Cp_original = sound_speed_profile[ssp_idx].c
    
    if len(Z_original) < NZmax:
        Z = np.zeros(NZmax)
        Cp = np.zeros(NZmax)
        Z[:len(Z_original)] = Z_original
        Cp[:len(Cp_original)] = Cp_original
        
        for i in range(len(Z_original), NZmax):
            if len(Z_original) > 1:
                Z[i] = Z_original[-1] + (i - len(Z_original) + 1) * 10
                Cp[i] = Cp_original[-1]
            else:
                Z[i] = i * 10
                Cp[i] = 1500
    else:
        Z = Z_original[:NZmax]
        Cp = Cp_original[:NZmax]
    
    Cs = np.zeros(len(Z))
    Rho = np.ones(len(Z))
    Ap = np.zeros(len(Z))
    As = np.zeros(len(Z))
    ssp_raw.append(SSPraw(Z, Cp, Cs, Rho, Ap, As))
    depth.append(Z[-1])

    Opt_top = 'SVW'
    N = np.zeros(NMedia, np.int8)
    Sigma = np.zeros(NMedia + 1)
    sspB = SSP(ssp_raw, depth, NMedia, Opt_top, N, Sigma)

    # Bottom option
    hs = HS(bottom_params[0].cp, bottom_params[0].cs, bottom_params[0].rho, bottom_params[0].a_p, bottom_params[0].a_s)
    Opt_bot = 'A~'
    bottom = BotBndry(Opt_bot, hs)
    top = TopBndry(Opt_top)
    bdy = Bndry(top, bottom)
    
    # Beam params setup
    run_type = 'C'
    box = Box(Zmax, max(bathymetry.r))
    deltas = 0
    
    # 为每个频率创建独立的环境文件
    Filenames = []
    for iF in range(Nfreq):
        freq = frequencies[iF]
        
        # 计算当前频率的射线参数
        if beam_number is not None and beam_number > 0:
            totalBeams = int(beam_number)
        else:
            if performance_mode:
                totalBeams = min(200, beamsnumber(freq, Rmax, max(bathymetry.d)))
            else:
                totalBeams = beamsnumber(freq, Rmax, max(bathymetry.d))
        
        # 计算角度范围
        if grazing_low is not None and grazing_high is not None:
            Alpha = [float(grazing_low), float(grazing_high)]
            NAlphaRange = 1
        else:
            if performance_mode:
                NAlphaRange = 6
            else:
                NAlphaRange = 12
            Alpha = alphadiv(NAlphaRange, Rmax)
        
        # 为当前频率创建多个角度分段文件
        if len(Alpha) == 2 and NAlphaRange == 1:
            # 用户指定角度范围
            alpha = np.array([float(Alpha[0]), float(Alpha[1])])
            nbeams = totalBeams
            beam = Beam(RunType=run_type, Nbeams=nbeams, alpha=alpha, box=box, deltas=deltas)
            filenameI = filename + f'_f{iF}_a0'
            write_env(filenameI + '.env', 'BELLHOP', 'Pekeris profile', freq, sspB, bdy, pos, beam, cint_obj, Rmax)
            write_ssp(filenameI, sound_speed_profile, bathymetry, NZmax)
            write_bathy(filenameI, bathymetry)
            Filenames.append(filenameI)
        else:
            # 多个角度分段
            for iAlphaRange in range(len(Alpha) - 1):
                alpha = np.array([float(Alpha[iAlphaRange]), float(Alpha[iAlphaRange + 1])])
                alpha_diff = float(alpha[1] - alpha[0])
                nbeams = int(totalBeams * alpha_diff / 180.0)
                nbeams = max(1, nbeams)
                beam = Beam(RunType=run_type, Nbeams=nbeams, alpha=alpha, box=box, deltas=deltas)
                filenameI = filename + f'_f{iF}_a{iAlphaRange}'
                write_env(filenameI + '.env', 'BELLHOP', 'Pekeris profile', freq, sspB, bdy, pos, beam, cint_obj, Rmax)
                write_ssp(filenameI, sound_speed_profile, bathymetry, NZmax)
                write_bathy(filenameI, bathymetry)
                Filenames.append(filenameI)
    
    # 并行执行所有频率和角度的计算
    pool = Pool(min(len(Filenames), 8))  # 限制并行进程数
    pool.map(call_Bellhop_p, Filenames)
    pool.close()
    pool.join()
    
    # 读取和组合结果
    if return_pressure:
        Pressure = np.zeros([1, Nfreq, len(RD), len(ran)], dtype=complex)
    TL_multi = np.zeros([Nfreq, len(RD), len(ran)])
    
    Pos1 = None
    for iF in range(Nfreq):
        pressure_sum = None
        
        # 读取当前频率的所有角度分段结果
        freq_filenames = [f for f in Filenames if f.endswith(f'_f{iF}_a0') or f'_f{iF}_a' in f]
        freq_filenames = [f for f in Filenames if f'_f{iF}_a' in f]
        
        for filenameI in freq_filenames:
            try:
                [x, x, x, x, Pos1, pressure] = read_shd(filenameI + '.shd')
                if pressure_sum is None:
                    pressure_sum = pressure.copy()
                else:
                    pressure_sum = pressure_sum + pressure
            except Exception as e:
                print(f"Warning: Failed to read {filenameI}.shd: {e}")
                continue
        
        if pressure_sum is not None:
            # 计算传输损失
            TL_multi[iF, :, :] = calculate_transmission_loss(pressure_sum)
            
            if return_pressure:                Pressure[0, iF, :, :] = pressure_sum[0, 0, :, :]
    
    if return_pressure:
        Pressure = np.squeeze(Pressure)
        return Pos1, TL_multi, Pressure
    else:
        return Pos1, TL_multi


def write_ssp(sspfile, ssp, bathm, NZmax):
    if sspfile[-3:] != 'ssp':
        sspfile += '.ssp'    
    # **Ensure directory exists**
    os.makedirs(os.path.dirname(sspfile), exist_ok=True)
    
    with open(sspfile, 'w') as f:
        f.write(str(len(ssp)) + '\r\n')
        for val in bathm.r:
            f.write(str(val) + '\t')
        f.write('\r\n')
        for row in range(NZmax):
            for col in range(len(ssp)):
                if len(ssp[col].z) <= row:
                    f.write('{:4.6f}'.format(1800) + '\t')
                else:
                    f.write('{:6f}'.format(ssp[col].c[row]) + '\t')
            f.write('\r\n')
    return


def write_bathy(btyfile, bathm):
    if btyfile[-3:] != 'bty':
        btyfile += '.bty'    
    # **Ensure directory exists**
    os.makedirs(os.path.dirname(btyfile), exist_ok=True)
    
    with open(btyfile, 'w') as f:
        f.write('CS\r\n')
        f.write(str(len(bathm.d)) + '\r\n')
        for row in range(len(bathm.r)):
            f.write('  ' + str(bathm.r[row]) + ' ' + str(bathm.d[row]) + '\r\n')
    return


def calZmax(ssp):
    d = np.array([], dtype=int)
    for it in range(len(ssp)):
        d = np.append(d, len(ssp[it].z))
    NZmax =max(d)
    ssp_idx = np.argmax(d)
    Zmax = ssp[ssp_idx].z[-1]
    return NZmax, Zmax, ssp_idx

def call_Bellhop_p(filename):
    system(AtBinPath + "/bellhop " + filename)

def calculate_transmission_loss(pressure, min_db_threshold=-250.0):
    """
    Calculate transmission loss, handling numerical stability issues
    """
    pressure_magnitude = np.abs(pressure)
    
    # Avoid division by zero: set minimum pressure value
    min_pressure = 10**(min_db_threshold / 20.0)
    pressure_magnitude = np.maximum(pressure_magnitude, min_pressure)
    
    # 计算传输损失
    TL = -20 * np.log10(pressure_magnitude)
    
    # 限制最大TL值
    max_TL = -min_db_threshold
    TL = np.minimum(TL, max_TL)
    
    return TL

def call_Bellhop(frequency, source_depth, receiver_depths, receiver_ranges, 
                 bathymetry, sound_speed_profile, sediment, bottom_params,
                 return_pressure=False, performance_mode=False, 
                 beam_number=None, grazing_high=None, grazing_low=None):
    """
    统一的Bellhop计算函数
    
    Args:
        frequency: 频率
        source_depth: 声源深度
        receiver_depths: 接收器深度数组
        receiver_ranges: 接收器距离数组
        bathymetry: 测深数据
        sound_speed_profile: 声速剖面
        sediment: 沉积层数据
        bottom_params: 底质参数
        return_pressure: 是否返回压力数据，默认False
        performance_mode: 性能模式，True时减少计算量，默认False
        beam_number: 用户指定的射线数量，默认None（自动计算）
        grazing_high: 掠射角上限（度），默认None
        grazing_low: 掠射角下限（度），默认None
    
    Returns:
        如果return_pressure=False: (Pos1, TL)
        如果return_pressure=True: (Pos1, TL, pressure)
    """
    # Source and receiving position
    filename = 'data/tmp/envB'
    
    # **确保目录存在**
    os.makedirs('data/tmp', exist_ok=True)    # **Always use user-provided precise grid data**
    # receiver_depths is already the user-provided depth grid, receiver_ranges is the user-provided range grid
    ran = np.array(receiver_ranges) / 1000.0  # Convert input meters to km for Bellhop internal use
    RD = np.array(receiver_depths)  # Keep receiver depths in original units (meters)
    Rmax = max(ran)  # Maximum range in km for internal calculations
    print(f"Using user-defined grid: {len(receiver_ranges)} range points, {len(RD)} depth points")
    
    # Calculate sound speed profile related parameters
    NZmax, Zmax, ssp_idx = calZmax(sound_speed_profile)
    
    pos = Pos(Source(source_depth), Dom(ran, RD))
    
    # Range of phase velocity
    cint_obj = cInt(1400, 15000)

    # The number of media
    NMedia = 1
    ssp_raw = []
    depth = [0]
    # Sound speed profile - 确保数组长度与NZmax一致
    Z_original = sound_speed_profile[ssp_idx].z  # 原始深度
    Cp_original = sound_speed_profile[ssp_idx].c  # 原始声速
    
    # 如果原始数组长度小于NZmax，需要扩展
    if len(Z_original) < NZmax:
        # 扩展深度数组到NZmax长度
        Z = np.zeros(NZmax)
        Cp = np.zeros(NZmax)
        
        # 复制原始数据
        Z[:len(Z_original)] = Z_original
        Cp[:len(Cp_original)] = Cp_original
        
        # 对缺失的点进行线性插值或使用最后一个值
        for i in range(len(Z_original), NZmax):
            if len(Z_original) > 1:
                # 使用最后一个值
                Z[i] = Z_original[-1] + (i - len(Z_original) + 1) * 10  # 每10米一个点
                Cp[i] = Cp_original[-1]  # 使用最后的声速值
            else:
                Z[i] = i * 10  # 默认每10米
                Cp[i] = 1500  # 默认声速
    else:
        # 如果长度匹配或更长，直接使用前NZmax个点
        Z = Z_original[:NZmax]
        Cp = Cp_original[:NZmax]
    
    # **确保所有数组长度一致**
    Cs = np.zeros(len(Z))  # Speed of S-wave
    Rho = np.ones(len(Z))  # Density of the media  
    Ap = np.zeros(len(Z))  # Attenuation of P-wave
    As = np.zeros(len(Z))  # Attenuation of S-wave
    ssp_raw.append(SSPraw(Z, Cp, Cs, Rho, Ap, As))
    depth.append(Z[-1])

    Opt_top = 'SVW'
    N = np.zeros(NMedia, np.int8)
    Sigma = np.zeros(NMedia + 1)
    sspB = SSP(ssp_raw, depth, NMedia, Opt_top, N, Sigma)

    #  Bottom option
    hs = HS(bottom_params[0].cp, bottom_params[0].cs, bottom_params[0].rho, bottom_params[0].a_p, bottom_params[0].a_s)
    Opt_bot = 'A~'
    bottom = BotBndry(Opt_bot, hs)
    top = TopBndry(Opt_top)
    bdy = Bndry(top, bottom)
    
    # Beam params - 使用用户提供的参数或默认计算
    run_type = 'C'  # incoherently sum beams, see AT docs for more info
    
    # 使用用户提供的射线数量或自动计算
    if beam_number is not None and beam_number > 0:
        totalBeams = int(beam_number)
        print(f"使用用户指定的射线数量: {totalBeams}")
    else:
        if performance_mode:
            # **性能模式：减少角度分段数和声线数量**
            totalBeams = min(200, beamsnumber(frequency, Rmax, max(bathymetry.d)))  # 限制最大声线数
        else:
            # **标准模式：完整精度计算**
            totalBeams = beamsnumber(frequency, Rmax, max(bathymetry.d))
        print(f"自动计算的射线数量: {totalBeams}")
    
    # 使用用户提供的掠射角范围或自动计算
    if grazing_low is not None and grazing_high is not None:
        # 使用用户提供的角度范围
        Alpha = [float(grazing_low), float(grazing_high)]
        NAlphaRange = 2  # 直接使用用户提供的范围，不再分段
        print(f"使用用户指定的掠射角范围: {grazing_low}° 到 {grazing_high}°")
    else:
        # 自动计算角度范围
        if performance_mode:
            NAlphaRange = 6  # 减少角度分段数
        else:
            NAlphaRange = 12
        Alpha = alphadiv(NAlphaRange, Rmax)  # min and max launch angle
        print(f"自动计算的掠射角范围: {Alpha[0]:.1f}° 到 {Alpha[-1]:.1f}°")
        
    box = Box(Zmax, max(bathymetry.r))  # bound the region you let the beams go, depth in meters and range in km
    deltas = 0  # length step of ray trace, 0 means automatically choose

    # Write *.env file
    ialpha = 0
    Filenames = []
    
    # 根据Alpha的长度确定处理方式
    if len(Alpha) == 2:
        # 用户指定的角度范围，直接使用
        alpha = np.array([float(Alpha[0]), float(Alpha[1])])
        nbeams = totalBeams
        beam = Beam(RunType=run_type, Nbeams=nbeams, alpha=alpha, box=box, deltas=deltas)
        filenameI = filename + '0'
        write_env(filenameI + '.env', 'BELLHOP', 'Pekeris profile', frequency, sspB, bdy, pos, beam, cint_obj, Rmax)
        write_ssp(filenameI, sound_speed_profile, bathymetry, NZmax)
        write_bathy(filenameI, bathymetry)
        Filenames.append(filenameI)
        NAlphaRange = 1  # 只有一个角度范围
    else:
        # 自动计算的多个角度分段
        for iAlphaRange in range(len(Alpha) - 1):
            alpha = np.array([float(Alpha[iAlphaRange]), float(Alpha[iAlphaRange + 1])])
            # 确保计算中的数值类型正确，修复类型错误
            alpha_diff = float(alpha[1] - alpha[0])
            nbeams = int(totalBeams * alpha_diff / 180.0)
            # 确保nbeams至少为1
            nbeams = max(1, nbeams)
            beam = Beam(RunType=run_type, Nbeams=nbeams, alpha=alpha, box=box, deltas=deltas)
            filenameI = filename + str(iAlphaRange)
            write_env(filenameI + '.env', 'BELLHOP', 'Pekeris profile', frequency, sspB, bdy, pos, beam, cint_obj, Rmax)
            write_ssp(filenameI, sound_speed_profile, bathymetry, NZmax)
            write_bathy(filenameI, bathymetry)
            Filenames.append(filenameI)

    pool = Pool(NAlphaRange)
    pool.map(call_Bellhop_p, Filenames)
    pool.close()
    pool.join()  # Read sound field
    
    # 初始化默认返回值
    Pos1 = None
    TL = None
    pressure = None
    
    try:
        [x, x, x, x, Pos1, pressure] = read_shd(filename + '0.shd')
        for iAlphaRange in range(NAlphaRange - 1):
            [x, x, x, x, Pos1, pressure1] = read_shd(filename + str(iAlphaRange + 1) + '.shd')
            pressure = pressure + pressure1
        # 计算传输损失
        TL = calculate_transmission_loss(pressure)
        
        # **根据参数决定返回值**
        if return_pressure:
            return Pos1, TL, pressure
        else:
            return Pos1, TL
        
    except Exception as e:
        # 创建默认的返回值
        default_pos = Pos(Source(source_depth), Dom(ran, RD))
        TL = np.full((len(RD), len(ran)), 100.0)
        
        if return_pressure:
            pressure = np.zeros((len(RD), len(ran)), dtype=complex)
            return default_pos, TL, pressure
        else:
            return default_pos, TL

def call_Bellhop_Rays(frequency, source_depth, receiver_depths, receiver_ranges,
                      bathymetry, sound_speed_profile, sediment, bottom_params,
                      beam_number=None, grazing_high=None, grazing_low=None):
    """
    Bellhop ray tracing calculation function
    
    Args:
        frequency: frequency (Hz)
        source_depth: source depth (m)
        receiver_depths: receiver depth array (m)
        receiver_ranges: receiver range array (m)
        bathymetry: bathymetry data
        sound_speed_profile: sound speed profile
        sediment: sediment layer data
        bottom_params: bottom parameters
        beam_number: 用户指定的射线数量，默认None（自动计算）
        grazing_high: 掠射角上限（度），默认None
        grazing_low: 掠射角下限（度），默认None
    
    Returns:
        ray tracing results
    """
    # Source and receiving position
    filename = 'data/tmp/cz'  # 修复文件名路径
    
    # **确保目录存在**    os.makedirs('data/tmp', exist_ok=True)
    
    # **Always use user-provided precise grid data**
    # receiver_depths is already the user-provided depth grid, receiver_ranges is the user-provided range grid
    ran = np.array(receiver_ranges) / 1000.0  # Convert input meters to km for Bellhop internal use
    RD = np.array(receiver_depths)  # Keep receiver depths in original units (meters)
    Rmax = max(ran)  # Maximum range in km for internal calculations
    print(f"Ray tracing with user-defined grid: {len(receiver_ranges)} range points, {len(RD)} depth points")
    
    # Calculate sound speed profile related parameters
    NZmax, Zmax, ssp_idx = calZmax(sound_speed_profile)
    
    pos = Pos(Source(source_depth), Dom(ran, RD))
    
    # Range of phase velocity
    cint_obj = cInt(1400, 15000)

    # The number of media
    NMedia = 1
    ssp_raw = []
    depth = [0]
    # Sound speed profile
    Z = sound_speed_profile[ssp_idx].z  # Depth
    Cp = sound_speed_profile[ssp_idx].c  # Speed of P-wave
    Cs = np.zeros(np.shape(Z))  # Speed of S-wave
    Rho = np.ones(np.shape(Z))  # Density of the media
    Ap = np.zeros(np.shape(Z))  # Attenuation of P-wave
    As = np.zeros(np.shape(Z))  # Attenuation of S-wave
    ssp_raw.append(SSPraw(Z, Cp, Cs, Rho, Ap, As))
    depth.append(Z[-1])

    # Sediment is ignored
    '''
    if sediment != None:
        Z =  sediment[0].z + sound_speed_profile[0].z[-1]  # Depth
        Cp = sediment[0].cp     # Speed of P-wave
        Cs = sediment[0].cs     # Speed of S-wave
        Rho = sediment[0].rho   # Density of the media
        Ap = sediment[0].a_p    # Attenuation of P-wave
        As = sediment[0].a_s    # Attenuation of S-wave
        ssp_raw.append(SSPraw(Z, Cp, Cs, Rho, Ap, As))
        depth.append(Z[-1])
    '''

    Opt_top = 'SVW'
    N = np.zeros(NMedia, np.int8)
    Sigma = np.zeros(NMedia + 1)
    sspB = SSP(ssp_raw, depth, NMedia, Opt_top, N, Sigma)

    #  Bottom option
    hs = HS(bottom_params[0].cp, bottom_params[0].cs, bottom_params[0].rho, bottom_params[0].a_p, bottom_params[0].a_s)
    Opt_bot = 'A~'
    bottom = BotBndry(Opt_bot, hs)
    top = TopBndry(Opt_top)
    bdy = Bndry(top, bottom)
    
    # Beam params - 使用用户提供的参数或默认值
    run_type = 'R'  # ray trace mode
    
    # 使用用户提供的射线数量或默认值
    if beam_number is not None and beam_number > 0:
        nbeams = int(beam_number)
        print(f"使用用户指定的射线数量: {nbeams}")
    else:
        nbeams = 301  # 默认射线数量
        print(f"使用默认射线数量: {nbeams}")
    
    # 使用用户提供的掠射角范围或默认值
    if grazing_low is not None and grazing_high is not None:
        alpha = np.array([float(grazing_low), float(grazing_high)])
        print(f"使用用户指定的掠射角范围: {grazing_low}° 到 {grazing_high}°")
    else:
        alpha = np.linspace(-10, 10, 2)  # 默认角度范围 -10° 到 10°
        print(f"使用默认掠射角范围: {alpha[0]:.1f}° 到 {alpha[1]:.1f}°")
        
    box = Box(Zmax, max(bathymetry.r))  # bound the region you let the beams go, depth in meters and range in km
    deltas = 0  # length step of ray trace, 0 means automatically choose
    beam = Beam(RunType=run_type, Nbeams=nbeams, alpha=alpha, box=box, deltas=deltas)  # package

    # Write *.env file
    write_env(filename + '.env', 'BELLHOP', 'Pekeris profile', frequency, sspB, bdy, pos, beam, cint_obj, Rmax)
    write_bathy(filename, bathymetry)

    system(AtBinPath + "/bellhop " + filename)
    # Read sound field
    return get_rays(filename + ".ray")

def find_cvgcRays(rays_total, bathymetry=None):
    """筛选有效射线，基于声学原理的宽松筛选策略"""
    Rays = []
    
    # 动态计算深度阈值 - 仅用于过滤明显异常的射线
    if bathymetry is not None:
        # 检查bathymetry对象的属性结构
        if hasattr(bathymetry, 'd'):
            min_bottom_depth = min(bathymetry.d)
        elif hasattr(bathymetry, 'depth'):
            min_bottom_depth = min(bathymetry.depth)
        else:
            try:
                min_bottom_depth = min(bathymetry)
            except (TypeError, ValueError):
                print("警告: bathymetry对象结构未知，使用默认深度阈值")
                min_bottom_depth = 100
        # 使用非常宽松的深度阈值，仅过滤明显异常的射线
        # 设置为海底深度的20%，主要过滤数值计算错误产生的异常浅射线
        depth_threshold = max(10, min_bottom_depth * 0.2)
    else:
        depth_threshold = 10  # 非常宽松的默认阈值
    
    print(f"射线筛选深度阈值: {depth_threshold:.1f}m (仅过滤异常浅射线)")
    
    # 简化筛选逻辑：只过滤明显无效的射线
    valid_rays = 0
    empty_rays = 0
    shallow_rays = 0
    
    for ray in rays_total[0]:
        # 跳过空射线（无坐标数据）
        if ray.xy.size == 0:
            empty_rays += 1
            continue
            
        # 检查射线是否过浅（可能是计算错误）
        max_depth = max(ray.xy[1,:])
        if max_depth < depth_threshold:
            shallow_rays += 1
            continue
        
        # 保留所有其他射线，不限制反射次数
        Rays.append(ray)
        valid_rays += 1
    
    print(f"射线筛选统计:")
    print(f"  - 总射线数: {len(rays_total[0])}")
    print(f"  - 空射线: {empty_rays}")
    print(f"  - 过浅射线 (<{depth_threshold:.1f}m): {shallow_rays}")
    print(f"  - 有效射线: {valid_rays}")
    print(f"  - 保留率: {valid_rays/len(rays_total[0])*100:.1f}%")
    
    return Rays

def alphadiv(NalphaRange, Rmax):
    """计算声线角度分布"""
    angle = [-90, 90]
    if Rmax > 100 and Rmax <= 1000:
        sigma = 20
    elif Rmax >= 1000:
        sigma = 15
    else:
        sigma = 25
    for i in range(1, NalphaRange):
        # 确保返回的角度是数值类型
        angle_val = float(norm.ppf(i / NalphaRange, loc=0, scale=sigma))
        angle.append(angle_val)

    angle.sort()
    # 确保返回的列表中都是数值类型
    return [float(a) for a in angle]

def beamsnumber(freq, Rmax, depth):
    """计算声线数量"""
    # 确保所有参数都是数值类型
    freq = float(freq)
    Rmax = float(Rmax)
    depth = float(depth)
    
    if Rmax > 700:
        nbeams = max(int(0.01 * Rmax * 1000 * freq / 1500), 300)
    elif Rmax > 300 and Rmax <= 700:
        nbeams = max(int(0.05 * Rmax * 1000 * freq / 1500), 300)
    elif Rmax > 100 and Rmax <= 300:
        nbeams = max(int(0.1 * Rmax * 1000 * freq / 1500), 300)
    else:
        nbeams = max(int(0.3 * Rmax * 1000 * freq / 1500), 300)

    d_theta_recommended = math.atan(depth / (10.0 * Rmax * 1000))
    nbeams = min(int(math.pi / d_theta_recommended), nbeams, 3000)

    return nbeams
# if __name__=="__main__":
    ''' ********************************************** '''
    ''' ******************** Test ******************** '''
    # freq = 25                        # Frequency
    # sd = np.array([10.0])            # Source depth
    # rd = np.linspace(0, 4000, 401)   # Receiving depth
    # # 定义坐标
    # lat = 19.00
    # lon = 116.00
    # # 定义时间段
    # timeIndex = db.timeDict['Annual']
    # # 创建类
    # data = db.DataBase()
    # # 设置时间段
    # data.set_timePeriod(timeIndex)

    # [bathm, ssp, sed, base] = GetEnv(data, freq, Coord(lon, lat), R=100, azi=90)
    # [Pos, TL] = call_Bellhop(freq, sd, rd, bathm, ssp, sed, base)

    # #[x, x, x, x, Pos, pressure] = read_shd('envB.shd')
    # #TL = -10 * np.log10(np.square(np.abs(pressure)))  # Transmission Loss
    # # Plot
    # plt.pcolor(Pos.r.range, Pos.r.depth, TL[0,0,:,:], vmin=40, vmax=130,cmap='jet_r', shading='auto')
    # plt.xlabel("Range/m")
    # plt.ylabel("Depth/m")
    # plt.gca().invert_yaxis()
    # plt.colorbar()    # plt.plot(bathm.r*1000, bathm.d, color='k')
    # plt.show()