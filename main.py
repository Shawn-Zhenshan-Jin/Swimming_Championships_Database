#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Apr 18 15:31:38 2017

@author: zhenshan
"""
import util

database_password= 'You PostSQL database cdoe'
userName = 'Your user name in PostgreSQL database'
conn_str="dbname='postgres' user=%s host='localhost' password=%s"%(userName, database_password)

util.MainMenu(conn_str)