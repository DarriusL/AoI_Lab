# @Time   : 2023.09.19
# @Author : Darrius Lei
# @Email  : darrius.lei@outlook.com
from dataclasses import dataclass
import numpy as np

@dataclass
class Data:
    pass



class SingleSystem():
    '''M terminals and a base station
    '''
    def __init__(self) -> None:
        pass

    def ter_retrieve_data(self, ts, arr_logis) -> None:
        '''
        Terminals retrieve data each timeslot.

        Parameters:
        ----------

        '''
        pass

    def ter_transport(self, id, ts, trans_rand) -> None:
        '''
        Terminals transport data to the base station.

        Parameters:
        ----------
        '''
        pass
    
    def bs_recive(self, ts, ts_tem) -> None:
        '''
        The Base station recive data from M terminals with the transmission blocking probability.

        Parameterss:
        ------------
        '''
        pass

    def cal_AoI(self, ts):
        '''
        Calculate the age of information between bs and each terminal.

        Parameters:
        -----------

        '''
        pass

    def simulate(self, rounds):
        '''
        System begin simulation.

        '''
        pass;