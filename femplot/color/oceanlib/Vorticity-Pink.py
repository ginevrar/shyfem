
from matplotlib.colors import ListedColormap
from numpy import nan, inf

# Used to reconstruct the colormap in pycam02ucs.cm.viscm
parameters = {'xp': [15.049331455581438, 29.258733164983113, 35.241639147889117, 27.389075045325001, 12.805741711991686, 0.83992974617973459],
              'yp': [-9.9358974358974308, -14.797008547008545, 0.1602564102564088, 16.613247863247864, 18.482905982905976, 0.53418803418804828],
              'min_Jp': 15.067114094,
              'max_Jp': 97.9530201342}

cm_data = [[ 0.20340025, 0.05125715, 0.20853721],
           [ 0.20826202, 0.05257439, 0.2129329 ],
           [ 0.21313526, 0.05385492, 0.21730306],
           [ 0.21802045, 0.05509893, 0.22164676],
           [ 0.22291807, 0.05630663, 0.225963  ],
           [ 0.22782852, 0.05747825, 0.23025069],
           [ 0.23275618, 0.05860748, 0.23451143],
           [ 0.23769737, 0.0597012 , 0.23874094],
           [ 0.24265208, 0.06076033, 0.24293764],
           [ 0.24762052, 0.06178533, 0.24710008],
           [ 0.25260288, 0.06277675, 0.25122673],
           [ 0.25759927, 0.06373523, 0.25531596],
           [ 0.26260976, 0.0646615 , 0.25936605],
           [ 0.26763544, 0.06555455, 0.26337578],
           [ 0.27267598, 0.06641579, 0.26734303],
           [ 0.27773011, 0.06724828, 0.27126523],
           [ 0.28279763, 0.06805326, 0.27514038],
           [ 0.28787829, 0.06883212, 0.27896641],
           [ 0.29297177, 0.06958642, 0.28274117],
           [ 0.29807765, 0.07031788, 0.28646248],
           [ 0.30319545, 0.07102842, 0.29012809],
           [ 0.30832464, 0.07172011, 0.29373575],
           [ 0.31346457, 0.07239524, 0.29728315],
           [ 0.31861455, 0.07305628, 0.300768  ],
           [ 0.3237738 , 0.0737059 , 0.304188  ],
           [ 0.32894146, 0.07434697, 0.30754086],
           [ 0.33411661, 0.07498254, 0.31082433],
           [ 0.33929826, 0.07561586, 0.31403622],
           [ 0.34448536, 0.07625034, 0.31717438],
           [ 0.34967708, 0.07688902, 0.32023675],
           [ 0.35487306, 0.07753419, 0.32322125],
           [ 0.36007097, 0.07819169, 0.32612604],
           [ 0.36526951, 0.07886553, 0.32894943],
           [ 0.37046736, 0.07955978, 0.33168987],
           [ 0.37566316, 0.08027858, 0.33434595],
           [ 0.38085553, 0.08102606, 0.33691649],
           [ 0.38604309, 0.08180633, 0.33940046],
           [ 0.39122561, 0.08262142, 0.34179654],
           [ 0.39640071, 0.08347702, 0.34410442],
           [ 0.40156669, 0.08437758, 0.3463239 ],
           [ 0.40672217, 0.08532677, 0.34845483],
           [ 0.41186583, 0.08632804, 0.35049732],
           [ 0.41699698, 0.08738362, 0.35245124],
           [ 0.4221141 , 0.08849693, 0.35431721],
           [ 0.42721549, 0.08967152, 0.35609639],
           [ 0.43230001, 0.09090969, 0.35778975],
           [ 0.43736661, 0.09221344, 0.35939846],
           [ 0.4424148 , 0.09358362, 0.36092332],
           [ 0.44744296, 0.09502266, 0.36236656],
           [ 0.45245022, 0.09653153, 0.36372988],
           [ 0.4574358 , 0.09811082, 0.36501514],
           [ 0.46239915, 0.09976065, 0.36622412],
           [ 0.46733939, 0.10148133, 0.36735917],
           [ 0.47225593, 0.1032726 , 0.36842255],
           [ 0.47714828, 0.10513387, 0.3694165 ],
           [ 0.48201596, 0.10706442, 0.37034344],
           [ 0.48685856, 0.10906325, 0.37120582],
           [ 0.49167582, 0.11112909, 0.37200598],
           [ 0.4964675 , 0.11326054, 0.37274632],
           [ 0.50123327, 0.11545624, 0.37342952],
           [ 0.50597299, 0.11771456, 0.37405808],
           [ 0.51068666, 0.12003365, 0.37463413],
           [ 0.51537424, 0.12241171, 0.37516003],
           [ 0.52003564, 0.12484701, 0.37563826],
           [ 0.52467068, 0.12733788, 0.37607164],
           [ 0.52927965, 0.12988221, 0.3764618 ],
           [ 0.53386261, 0.13247818, 0.37681091],
           [ 0.53841965, 0.13512398, 0.3771211 ],
           [ 0.54295065, 0.13781801, 0.37739515],
           [ 0.54745584, 0.14055843, 0.37763473],
           [ 0.55193545, 0.14334348, 0.37784149],
           [ 0.5563896 , 0.14617156, 0.37801733],
           [ 0.56081843, 0.14904112, 0.3781641 ],
           [ 0.56522185, 0.15195079, 0.3782845 ],
           [ 0.5696002 , 0.15489902, 0.37837948],
           [ 0.57395365, 0.15788445, 0.37845058],
           [ 0.57828232, 0.16090583, 0.37849943],
           [ 0.58258634, 0.16396195, 0.3785276 ],
           [ 0.58686572, 0.1670517 , 0.37853726],
           [ 0.59112064, 0.17017398, 0.3785295 ],
           [ 0.59535127, 0.17332779, 0.37850546],
           [ 0.5995577 , 0.1765122 , 0.37846653],
           [ 0.60374   , 0.17972635, 0.37841404],
           [ 0.60789824, 0.18296943, 0.37834937],
           [ 0.61203242, 0.18624067, 0.37827444],
           [ 0.61614266, 0.1895394 , 0.37818974],
           [ 0.62022902, 0.19286498, 0.37809649],
           [ 0.6242915 , 0.19621684, 0.37799588],
           [ 0.62833011, 0.19959444, 0.37788907],
           [ 0.63234486, 0.2029973 , 0.3777772 ],
           [ 0.63633567, 0.20642491, 0.3776619 ],
           [ 0.64030257, 0.20987692, 0.37754374],
           [ 0.6442455 , 0.21335297, 0.37742379],
           [ 0.64816439, 0.21685275, 0.37730312],
           [ 0.65205918, 0.22037597, 0.37718281],
           [ 0.65592975, 0.22392235, 0.37706391],
           [ 0.659776  , 0.22749166, 0.37694762],
           [ 0.66359781, 0.23108369, 0.376835  ],
           [ 0.66739504, 0.2346983 , 0.37672691],
           [ 0.67116753, 0.23833535, 0.3766244 ],
           [ 0.67491512, 0.24199472, 0.37652853],
           [ 0.67863762, 0.2456763 , 0.37644035],
           [ 0.68233484, 0.24938002, 0.37636095],
           [ 0.68600655, 0.2531058 , 0.37629145],
           [ 0.68965253, 0.2568536 , 0.37623291],
           [ 0.69327254, 0.2606234 , 0.37618635],
           [ 0.69686632, 0.2644152 , 0.37615291],
           [ 0.7004336 , 0.26822899, 0.37613371],
           [ 0.70397409, 0.27206478, 0.3761299 ],
           [ 0.7074875 , 0.27592259, 0.37614266],
           [ 0.71097352, 0.27980245, 0.37617313],
           [ 0.71443181, 0.28370442, 0.37622252],
           [ 0.71786206, 0.28762852, 0.37629208],
           [ 0.7212639 , 0.2915748 , 0.37638306],
           [ 0.724637  , 0.29554332, 0.37649676],
           [ 0.72798098, 0.29953413, 0.37663448],
           [ 0.73129546, 0.30354729, 0.37679757],
           [ 0.73458005, 0.30758288, 0.37698731],
           [ 0.73783435, 0.31164097, 0.37720511],
           [ 0.74105798, 0.31572158, 0.37745245],
           [ 0.74425052, 0.31982476, 0.37773081],
           [ 0.74741157, 0.32395055, 0.37804166],
           [ 0.75054072, 0.328099  , 0.37838654],
           [ 0.75363755, 0.33227014, 0.378767  ],
           [ 0.75670159, 0.33646406, 0.37918448],
           [ 0.75973246, 0.34068073, 0.37964068],
           [ 0.76272975, 0.34492014, 0.38013731],
           [ 0.76569305, 0.34918228, 0.38067601],
           [ 0.76862195, 0.35346712, 0.3812585 ],
           [ 0.77151605, 0.35777464, 0.38188648],
           [ 0.77437495, 0.36210479, 0.38256169],
           [ 0.77719822, 0.36645754, 0.38328582],
           [ 0.77998556, 0.37083276, 0.38406076],
           [ 0.7827366 , 0.37523032, 0.38488831],
           [ 0.785451  , 0.3796501 , 0.38577027],
           [ 0.78812845, 0.38409196, 0.38670846],
           [ 0.79076866, 0.38855573, 0.3877047 ],
           [ 0.79337135, 0.3930412 , 0.38876082],
           [ 0.7959363 , 0.39754813, 0.38987866],
           [ 0.79846329, 0.40207627, 0.39106003],
           [ 0.80095214, 0.40662536, 0.39230669],
           [ 0.8034027 , 0.4111951 , 0.39362043],
           [ 0.80581485, 0.41578517, 0.39500298],
           [ 0.80818855, 0.42039519, 0.39645606],
           [ 0.8105239 , 0.42502464, 0.39798147],
           [ 0.8128208 , 0.42967323, 0.39958071],
           [ 0.8150793 , 0.43434053, 0.40125532],
           [ 0.81729951, 0.43902609, 0.40300681],
           [ 0.81948157, 0.44372941, 0.40483662],
           [ 0.82162569, 0.44844998, 0.40674611],
           [ 0.82373229, 0.45318712, 0.40873667],
           [ 0.82580183, 0.45794015, 0.41080953],
           [ 0.82783443, 0.4627087 , 0.41296566],
           [ 0.82983048, 0.46749218, 0.41520606],
           [ 0.83179047, 0.47228997, 0.41753164],
           [ 0.83371489, 0.47710144, 0.4199432 ],
           [ 0.83560431, 0.48192593, 0.42244142],
           [ 0.83745936, 0.4867628 , 0.4250269 ],
           [ 0.83928115, 0.49161102, 0.42770018],
           [ 0.84107035, 0.49646996, 0.43046153],
           [ 0.84282741, 0.50133921, 0.43331112],
           [ 0.84455311, 0.50621807, 0.43624906],
           [ 0.84624832, 0.51110586, 0.43927533],
           [ 0.8479139 , 0.51600192, 0.44238981],
           [ 0.84955078, 0.52090556, 0.44559226],
           [ 0.85115991, 0.52581613, 0.44888233],
           [ 0.85274227, 0.53073296, 0.45225954],
           [ 0.85429886, 0.5356554 , 0.45572335],
           [ 0.85583071, 0.54058284, 0.45927307],
           [ 0.85733888, 0.54551465, 0.46290794],
           [ 0.85882442, 0.55045025, 0.46662711],
           [ 0.86028873, 0.55538883, 0.47042955],
           [ 0.86173275, 0.56032997, 0.47431426],
           [ 0.86315731, 0.56527328, 0.47828022],
           [ 0.86456348, 0.57021827, 0.48232627],
           [ 0.86595233, 0.57516447, 0.48645122],
           [ 0.86732494, 0.58011144, 0.49065382],
           [ 0.86868234, 0.58505874, 0.49493276],
           [ 0.87002561, 0.59000599, 0.4992867 ],
           [ 0.87135575, 0.59495282, 0.50371428],
           [ 0.87267379, 0.5998989 , 0.50821409],
           [ 0.8739816 , 0.60484341, 0.5127843 ],
           [ 0.87527962, 0.6097864 , 0.51742369],
           [ 0.87656874, 0.61472764, 0.52213085],
           [ 0.87784992, 0.61966691, 0.52690431],
           [ 0.87912408, 0.62460401, 0.53174263],
           [ 0.88039211, 0.62953874, 0.53664435],
           [ 0.8816549 , 0.63447097, 0.54160802],
           [ 0.88291328, 0.63940055, 0.54663223],
           [ 0.88416808, 0.64432738, 0.55171557],
           [ 0.88542008, 0.64925139, 0.55685666],
           [ 0.88667005, 0.6541725 , 0.56205414],
           [ 0.88791872, 0.65909067, 0.56730668],
           [ 0.8891709 , 0.66400384, 0.57261005],
           [ 0.89042371, 0.66891382, 0.57796541],
           [ 0.89167767, 0.67382071, 0.58337159],
           [ 0.89293342, 0.67872453, 0.58882738],
           [ 0.89419156, 0.68362534, 0.59433158],
           [ 0.89545267, 0.68852319, 0.59988306],
           [ 0.89672032, 0.69341676, 0.60547834],
           [ 0.89799564, 0.6983059 , 0.61111575],
           [ 0.89927597, 0.70319221, 0.61679672],
           [ 0.90056181, 0.70807582, 0.62252022],
           [ 0.90185363, 0.71295684, 0.6282853 ],
           [ 0.9031548 , 0.7178341 , 0.63408853],
           [ 0.90446821, 0.7227067 , 0.63992685],
           [ 0.90578934, 0.72757702, 0.64580349],
           [ 0.90711857, 0.73244522, 0.65171762],
           [ 0.90845631, 0.73731145, 0.65766843],
           [ 0.90981225, 0.74217193, 0.66364681],
           [ 0.9111781 , 0.74703058, 0.66965958],
           [ 0.91255393, 0.75188769, 0.67570624],
           [ 0.91394046, 0.75674328, 0.68178577],
           [ 0.91534816, 0.76159342, 0.68788806],
           [ 0.9167672 , 0.76644249, 0.69402174],
           [ 0.9181979 , 0.77129068, 0.70018617],
           [ 0.91964557, 0.7761362 , 0.70637599],
           [ 0.92111262, 0.78097847, 0.71258846],
           [ 0.92259257, 0.78582038, 0.71882946],
           [ 0.92408634, 0.79066188, 0.72509782],
           [ 0.92560593, 0.7954987 , 0.73138149],
           [ 0.92713958, 0.80033571, 0.73769161],
           [ 0.92868761, 0.80517307, 0.74402771],
           [ 0.93026226, 0.81000656, 0.75037722],
           [ 0.93185391, 0.8148401 , 0.75674949],
           [ 0.93346107, 0.81967454, 0.76314584],
           [ 0.93509628, 0.82450566, 0.7695532 ],
           [ 0.9367501 , 0.82933722, 0.77598096],
           [ 0.93842059, 0.83417022, 0.78243098],
           [ 0.94012241, 0.83899979, 0.78888773],
           [ 0.94184257, 0.84383087, 0.79536454],
           [ 0.94358303, 0.84866304, 0.80185918],
           [ 0.94535503, 0.8534928 , 0.80835951],
           [ 0.94714576, 0.85832485, 0.81487893],
           [ 0.9489631 , 0.86315684, 0.82140881],
           [ 0.95080878, 0.86798852, 0.82794705],
           [ 0.95267455, 0.87282297, 0.8345024 ],
           [ 0.95457496, 0.87765571, 0.84105874],
           [ 0.95649898, 0.88249069, 0.8476279 ],
           [ 0.95844981, 0.8873272 , 0.85420614],
           [ 0.96043456, 0.89216329, 0.86078529],
           [ 0.96244207, 0.89700286, 0.86737746],
           [ 0.96448728, 0.90184151, 0.87396567],
           [ 0.96655947, 0.90668298, 0.88056151],
           [ 0.96866357, 0.91152607, 0.88715902],
           [ 0.97080349, 0.91636994, 0.89375329],
           [ 0.97297049, 0.92121764, 0.90035362],
           [ 0.97518156, 0.92606439, 0.9069399 ],
           [ 0.9774208 , 0.93091541, 0.91352937],
           [ 0.97970195, 0.93576702, 0.92010507],
           [ 0.98201829, 0.94062171, 0.9266731 ],
           [ 0.98437391, 0.94547881, 0.93322656],
           [ 0.98677194, 0.95033807, 0.93975862],
           [ 0.98920738, 0.95520176, 0.94627024],
           [ 0.99169155, 0.96006773, 0.95274067],
           [ 0.99421147, 0.96494148, 0.95917135]]

test_cm = ListedColormap(cm_data, name=__file__)


if __name__ == "__main__":
    import matplotlib.pyplot as plt
    import numpy as np

    try:
        from viscm import viscm
        viscm(test_cm)
    except ImportError:
        print("viscm not found, falling back on simple display")
        plt.imshow(np.linspace(0, 100, 256)[None, :], aspect='auto',
                   cmap=test_cm)
    plt.show()