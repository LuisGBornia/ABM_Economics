from mesa import Agent, Model
from mesa.time import RandomActivation
import random
import pandas as pd


global acao = 2/3
global din = 1-acao

class Agente(Agent):

    def __init__(self, N):
        self.qtde = random.randint(100, 300)
        self.cash = random.randint(5000, 10000)
        self.preco = random.randint(10, 100)
        self.util = (self.qtde**acao)+(self.cash**din)
        self.sold = False
        
