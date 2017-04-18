#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Apr 18 15:34:53 2017

@author: zhenshan
"""
import psycopg2
import Query # user-defined query interface
import CRUD # Create, read, Upate, Delete functions

def ReportError(conn_str):
    try:
        conn=psycopg2.connect(conn_str)
    except:
        print("I am unable to connect to the database")
        return;
    cur = conn.cursor()
    querry='SELECT * FROM ErrorOutput'
    cur.execute(querry)
    # Make the changes to the database persistent
    rows = cur.fetchall()
    conn.commit()
    # Close communication with the database
    for r in rows:
        print (r[1])
    querry='DELETE FROM ErrorOutput'
    cur.execute(querry)
    conn.commit()
    cur.close()
    conn.close()
    
def MainMenu(conn_str):

    menu = {}
    menu['1'] = "Read in a File. Example: SwimmingChampoinData.csv"
    menu['2'] = "Save Data to A File"
    menu['3'] = "Add A Row To A Table"
    menu['4'] = "Update a Row"

    menu['5'] = "Make a Heat Sheet For a Meet. Example: NCAA_Summer"
    menu['6'] = "Make a Heat Sheet for a Participant and Meet, Example: RICE,NCAA_Summer"
    menu['7'] = "Make a Heat Sheet for a School and Meet, Example: RICE,NCAA_Summer"
    menu['8'] = "For a School and Meet, Display Names of Swimmers, Example: RICE,NCAA_Summer"
    menu['9'] = "For an Event and Meet, Display all Times Sorted, Example: E0107,NCAA_Summer"
    menu['A'] = "For a Meet, Display the Scores. Example: NCAA_Summer"
    #menu['B'] = "Report Errors"
    menu['B'] = "Exit"
    menu_keys=['1', '2','3', '4','5', '6', '7', '8', '9', 'A', 'B' ]
    read_menu=True
    while(read_menu):
        for k in menu_keys:
            print(k, menu[k])

        selection=input("Please Select:")
        if(selection=='1'):
            CRUD.ReadFileMenu(conn_str)
        if(selection=='2'):
            #OutputTable(tableName, path):
            CRUD.OutputTable(conn_str)
        elif(selection=='3'):
            CRUD.AddRowMenu(conn_str)
        elif(selection=='4'):
            CRUD.ChangeRowMenu(conn_str)
        elif(selection=='5'):
            Query.HeatSheetMeetMenu(conn_str)
        elif(selection=='6'):
            Query.HeatSheetParticipantMeetMenu(conn_str)
        elif(selection=='7'):
            Query.HeatSheetSchoolMeetMenu(conn_str)
        elif(selection=='8'):
            Query.CompetingSwimmer(conn_str)
        elif(selection=='9'):
            Query.HeatSheetEventMeetMenu(conn_str)
        elif (selection=='A'):
            Query.MeetFinalScore(conn_str)
        #elif (selection=='B'):
        #     ReportError(conn_str)
        elif (selection=='B'):
            read_menu=False