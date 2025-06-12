from readwrite import write_env, read_shd, get_rays
from env import Pos, Source, Dom, cInt, SSPraw, SSP, HS, BotBndry, TopBndry, Bndry, Box, Beam
from os import system
import numpy as np
from config import AtBinPath
from multiprocessing import Pool
from scipy.stats import norm
import math
import os  # Add this import
import warnings


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
                 return_pressure=False, performance_mode=False):
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
    
    # Beam params - 根据性能模式调整参数
    run_type = 'C'  # incoherently sum beams, see AT docs for more info
    if performance_mode:
        # **性能模式：减少角度分段数和声线数量**
        NAlphaRange = 6  # 减少角度分段数
        totalBeams = min(200, beamsnumber(frequency, Rmax, max(bathymetry.d)))  # 限制最大声线数
    else:
        # **标准模式：完整精度计算**
        NAlphaRange = 12
        totalBeams = beamsnumber(frequency, Rmax, max(bathymetry.d))
    
    Alpha = alphadiv(NAlphaRange, Rmax)  # min and max launch angle
    box = Box(Zmax, max(bathymetry.r))  # bound the region you let the beams go, depth in meters and range in km
    deltas = 0  # length step of ray trace, 0 means automatically choose

    # Write *.env file
    ialpha = 0
    Filenames = []
    for iAlphaRange in range(len(Alpha) - 1):
        alpha = np.array([float(Alpha[iAlphaRange]), float(Alpha[iAlphaRange + 1])])
        # 确保计算中的数值类型正确，修复类型错误
        alpha_diff = float(alpha[1] - alpha[0])
        nbeams = int(totalBeams * alpha_diff / 180.0)
        # 确保nbeams至少为1
        nbeams = max(1, nbeams)
        beam = Beam(RunType=run_type, Nbeams=nbeams, alpha=alpha, box=box, deltas=deltas)  # package
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
                      bathymetry, sound_speed_profile, sediment, bottom_params):
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
    
    Returns:
        ray tracing results
    """
    # Source and receiving position
    filename = 'data/tmp/cz'  # 修复文件名路径
    
    # **确保目录存在**
    os.makedirs('data/tmp', exist_ok=True)
      # **Always use user-provided precise grid data**    # receiver_depths is already the user-provided depth grid, receiver_ranges is the user-provided range grid
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
    # Beam params
    nbeams = 301
    alpha = np.linspace(-10, 10, 2)  # min and max launch angle -20 degrees to 20 degrees
    box = Box(Zmax, max(bathymetry.r))  # bound the region you let the beams go, depth in meters and range in km
    deltas = 0  # length step of ray trace, 0 means automatically choose
    run_type = 'R'
    beam = Beam(RunType=run_type, Nbeams=nbeams, alpha=alpha, box=box, deltas=deltas)  # package

    # Write *.env file
    write_env(filename + '.env', 'BELLHOP', 'Pekeris profile', frequency, sspB, bdy, pos, beam, cint_obj, Rmax)
    write_bathy(filename, bathymetry)

    system(AtBinPath + "/bellhop " + filename)
    # Read sound field
    return get_rays(filename + ".ray")

def find_cvgcRays(rays_total):
    Rays = []
    num_bnc_min = np.Inf
    for ray in rays_total[0]:
        if ray.num_top_bnc + ray.num_bot_bnc < num_bnc_min and max(ray.xy[1,:]) > 100:
            num_bnc_min = ray.num_top_bnc + ray.num_bot_bnc

    for ray in rays_total[0]:
        if ray.num_top_bnc + ray.num_bot_bnc > num_bnc_min + 1:
            continue
        elif max(ray.xy[1,:]) < 100:
            continue
        else:
            Rays.append(ray)
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