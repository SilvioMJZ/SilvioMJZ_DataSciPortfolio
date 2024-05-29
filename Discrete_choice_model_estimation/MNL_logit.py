#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Sep 30 10:24:07 2023

@author: Silvio Mauricio Jurado Zenteno
"""
import os
import pandas as pd
import numpy as np
from scipy.optimize import minimize
import timeit
import matplotlib.pyplot as plt
import seaborn as sns
from numba import njit, jit
from concurrent.futures import ThreadPoolExecutor


os.chdir('/Volumes/ADATA_HD710/MacBook/COLMEX/Semestre_3/Elección_Discreta/')

elecciones = pd.read_csv("hw3_df_choices.csv")
atributos = pd.read_csv("hw3_df_data.csv")

elecciones['market_share'] = elecciones['id'].map(elecciones['id'].value_counts(normalize=True))
elecciones = elecciones.reset_index(drop=True).sort_values(by=['market_share', 'id'], ascending=[False, True]).reset_index(drop=True)
elecciones['rank'] = elecciones['market_share'].rank(method='dense', ascending=False).astype(int)
rank_id = elecciones[['id', 'market_share', 'rank']].drop_duplicates() # Haremos un nuevo pd con ranking y market share
mask_e = elecciones['rank'] > 9
elecciones.loc[mask_e, 'id'] = 5542
elecciones.loc[mask_e, 'rank'] = 11

# Filtraremos únicamente las variables que nos interesan, así como las nuevas alternativas

selec_col = ['id', 'hpwt', 'space', 'air', 'mpd', 'price', 'mpg']
atributos_filt = atributos[selec_col]
atributos_filt = pd.merge(atributos_filt, rank_id, how='inner', on='id')
atributos_filt = atributos_filt.reset_index(drop=True).sort_values(by=['market_share', 'id'], ascending=[False, True]).reset_index(drop=True)
mask_a = atributos_filt['rank'] > 9
atributos_filt.loc[mask_a, 'id'] = 5542
atributos_filt.loc[mask_a, 'rank'] = 11
mean_5542 = pd.DataFrame([atributos_filt[atributos_filt['id'] == 5542].mean()])
atributos_filt = atributos_filt[atributos_filt['id'] != 5542]
atributos_filt = pd.concat([atributos_filt, mean_5542], ignore_index=True)


# Haremos la expansión del conjunto de datos, con cada fila como alternativaXconsumidor
elecciones['key'] = 1
atributos_filt['key'] = 1
comb = pd.merge(elecciones, atributos_filt, on='key').drop('key', axis=1) # Producto cartesiano de ambos datasets
comb['log_ing_disp'] = np.log(comb['y_i']-comb['price'])
comb['ing_disp'] = comb['y_i']-comb['price']
comb['y_jn'] = np.where(comb['id_x'] == comb['id_y'], 1, 0) # Variable indicadora de elección
comb = comb.sort_values(by=['y_i', 'id_y']) 
comb['id_x'] = pd.factorize(comb['y_i'])[0] + 1
comb = comb.rename(columns={'id_x': 'consumidor'})
comb = comb.rename(columns={'id_y': 'id'})
comb = comb.rename(columns={'market_share_y': 'market_share', 'rank_y': 'rank'})
comb = comb.drop(['market_share_x', 'rank_x'], axis=1)


# Vamos a crear variables dummy para cada alternativa
dummies = pd.get_dummies(comb['id'], drop_first=True) # Uno de los interceptos será 0: el de referencia
comb = pd.concat([comb, dummies], axis=1)

z_jn = ['hpwt', 'space', 'air', 'mpd', 'mpg', 'log_ing_disp']

# Cálculos precomputados
dummies_vals = comb[dummies.columns].values
z_jn_vals = comb[z_jn].values
y_jn_vals = comb['y_jn'].values
precio_vals = comb.groupby('id')['price'].first().values
unique_consumidores = comb['consumidor'].unique()
consumidor_vals = comb['consumidor'].values
num_consumidores = len(elecciones)
num_alternativas = len(atributos_filt)
coefs_inicial = np.zeros(dummies_vals.shape[1] + z_jn_vals.shape[1]) 

historial = []

# Definiendo la función callback
def callback(coefs, *args):
    valor_f = neg_log_likelihood_3(coefs, *args)
    historial.append(valor_f)
    historial.append(coefs)
    print(f"Valor actual: {valor_f}")
    

# Utilizamos NUMBA para optimizar costo computacional

@jit
def calc_sum_exp_V(exp_V, inverses):
    sum_exp_V = np.bincount(inverses, weights=exp_V)
    return sum_exp_V

@jit
def neg_log_likelihood_3(coefs, dummies_vals, z_jn_vals, y_jn_vals, consumidor_vals):
    epsilon = 1e-10
    thetas_cero = coefs[:dummies_vals.shape[1]]
    thetas = coefs[dummies_vals.shape[1]:]

    utilidad_obs = np.dot(dummies_vals.astype(np.float64), thetas_cero) + np.dot(z_jn_vals, thetas)
    exp_V = np.exp(utilidad_obs)
    
    # Seleccionamos solo las utilidades de las opciones elegidas a través de una máscara booleana
    exp_V_elegida = exp_V[y_jn_vals == 1]
    
    _, inverses = np.unique(consumidor_vals, return_inverse=True)
    sum_exp_V = calc_sum_exp_V(exp_V, inverses)
        
    probs_cond = exp_V_elegida / sum_exp_V

    
    loglik = np.sum(np.log(probs_cond + epsilon))
    
    return -loglik


def minimizacion():
    args = (dummies_vals, z_jn_vals, y_jn_vals, consumidor_vals)
    return minimize(neg_log_likelihood_3, 
                    coefs_inicial, 
                    args=args, 
                    method='L-BFGS-B',  
                    callback=lambda coefs: callback(coefs, *args),
                    options={'gtol': 1e-3, 'maxiter': 1000, 
                             'disp': True})

resultados_min = minimizacion()
coefs_opt = resultados_min.x
np.save('coefs_opt.npy', coefs_opt)

print(timeit.timeit(minimizacion, number=1))

# Haremos el inverso del hessiano y lo guardamos como un np.array
   
hess_inv_np = np.asarray(resultados_min.hess_inv.todense())

# Calculamos los errores estándar de la diagonal de la matriz.

errores_asint = np.sqrt(np.diag(hess_inv_np))
np.save('erroes_asint.npy', errores_asint)

reps_boot = 3211

def puntos_aleatorios(size):
    return np.random.uniform(-1, 1, size=size)

def minimizacion_boot(muestra, coefs_inicial):
    args = (dummies_vals, z_jn_vals, y_jn_vals, consumidor_vals)
    return minimize(neg_log_likelihood_3, 
                    coefs_inicial, 
                    args=args, 
                    method='Powell',  
                    callback=lambda coefs: callback(coefs, *args),
                    options={'xtol': 1e-3, 'maxiter': 1000, 
                             'disp': True})

def run_bootstrap(_):
        muestra_boot = comb.sample(frac=1, replace=True)
        coefs_inicial = puntos_aleatorios(16)
        resultados_boot = minimizacion_boot(muestra_boot, coefs_inicial)
        return resultados_boot.x

with ThreadPoolExecutor() as executor:
    boot_coefs = list(executor.map(run_bootstrap, range(reps_boot)))

boot_coefs = np.array(boot_coefs)
errores_boot = boot_coefs.std(axis=0)
medias_boot = np.mean(errores_boot[:, np.newaxis], axis=1)

# Guardando
np.save('boot_coefs.npy', boot_coefs)
np.save('errores_boot.npy', errores_boot)

# Cargando
boot_coefs = np.load('boot_coefs.npy')

# Haremos histogramas de la distribución de los coeficientes

for i, variable in enumerate(z_jn):
    plt.figure()  # Crear una nueva figura
    plt.hist(boot_coefs[:, i], bins=50, edgecolor='k')
    plt.title(f'Distribución empírica de {variable}')
    plt.xlabel('Coeficiente')
    plt.ylabel('Frecuencia')
    plt.savefig(f'dist{variable}_.png', dpi=300)
    

# Ahora verificamos la calidad de la estimación

# Calculamos verosimilitud

verosimilitud = -neg_log_likelihood_3(coefs_opt, dummies_vals, z_jn_vals, y_jn_vals, consumidor_vals)

np.save('verosimilitud.npy', verosimilitud)

verosimilitud_cero = -neg_log_likelihood_3(coefs_inicial, dummies_vals, z_jn_vals, y_jn_vals, consumidor_vals)

# Calculamos índice de verosimilitud

ind_ver = 1 - (verosimilitud / verosimilitud_cero)

np.save('ind_ver.npy', ind_ver)

# Calculamos AIC

k = len(coefs_inicial) 

aic = -2 * verosimilitud + 2 * k

np.save('aic.npy', aic)

# Calcularemos elasticidades

# Partamos del array de probabilidades

@jit
def probs_cond(coefs, dummies_vals, z_jn_vals, y_jn_vals, consumidor_vals):
    thetas_cero = coefs[:dummies_vals.shape[1]]
    thetas = coefs[dummies_vals.shape[1]:]

    utilidad_obs = np.dot(dummies_vals.astype(np.float64), thetas_cero) + np.dot(z_jn_vals, thetas)
    exp_V = np.exp(utilidad_obs)
    
    _, inverses = np.unique(consumidor_vals, return_inverse=True)
    sum_exp_V = np.bincount(inverses, weights=exp_V)
    
    sum_exp_V_rep = np.repeat(sum_exp_V, 11)
    
    probs_cond = exp_V / sum_exp_V_rep
    
    return probs_cond

probs_cond = probs_cond(coefs_opt, dummies_vals, z_jn_vals, y_jn_vals, consumidor_vals)

# Obtenemos las derivadas de la utilidad con respecto a la característica del bien


def derivada_V(comb, coefs_opt):
    inv_ing_disp = 1 / comb['ing_disp']
    inv_ing_disp = np.asarray(1 / comb['ing_disp'])
    inv_ing_disp_r = inv_ing_disp.reshape(10000,11)
    inv_ing_disp_rep = np.repeat(inv_ing_disp_r, 11, axis=0)
    coef_log = coefs_opt[-1]
    derivada_V = inv_ing_disp_rep * coef_log
    return derivada_V
    
dx_V = np.asarray(derivada_V(comb, coefs_opt))
probs_cond = np.asarray(probs_cond)

# Obtenemos la matriz de elasticidades a partir de productos de probabilidades y del vector de derivadas

@njit
def elasticidades_matriz(probs_cond, dx_V, num_consumidores, num_alternativas):
    probs_matriz = np.zeros((num_consumidores*num_alternativas, num_alternativas))

    for n in range(num_consumidores):
        for i in range(num_alternativas):
            for j in range(num_alternativas):
                indicadora = 1 if i == j else 0
                Pi = probs_cond[n*num_alternativas + i]
                Pj = probs_cond[n*num_alternativas + j]
                probs_matriz[n*num_alternativas + i, j] = -1 * Pj * (Pi - indicadora)
    
    elasticidades_matriz = probs_matriz * dx_V

    return elasticidades_matriz

elasticidades_matriz = elasticidades_matriz(probs_cond, dx_V, num_consumidores, num_alternativas)

# Podemos hacer la matriz tridimensional para mejor visualización.

forma_3D = (num_consumidores, 11, 11)
elasticidades_matriz_3D = np.reshape(elasticidades_matriz, forma_3D)

np.save('elasticidades_matriz_3D.npy', elasticidades_matriz_3D)

# Ahora añadimos la columna de probabilidades:
    
forma_3D_2 = (num_consumidores, 11, 12)    
probs_cond = probs_cond[:, np.newaxis]
elasticidades_mat_plus  = np.concatenate([elasticidades_matriz, probs_cond], axis=1)
elasticidades_matriz_3D_plus = np.reshape(elasticidades_mat_plus, forma_3D_2)

np.save('elasticidades_matriz_3D_plus.npy', elasticidades_matriz_3D_plus)
    
