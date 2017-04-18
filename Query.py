#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Apr 18 15:34:09 2017

@author: zhenshan
"""
import psycopg2

def CompetingSwimmer(conn_str):
    try:
        conn = psycopg2.connect(conn_str)
    except:
        print("I am unable to connect to the database")
        return;
    
    print("Enter the name of the school and meet. Seperate them by commas, no space \n")
    schoolMeetName=input()
    arg_list=schoolMeetName.split(",")
    
    cur = conn.cursor()
    cur.callproc('SchoolMeet2', (arg_list[0],arg_list[1], ))
    rows = cur.fetchall()
    # Make the changes to the database persistent
    conn.commit()

    # Close communication with the database
    cur.close()
    conn.close()
    
    print("\nAthlete Name")
    for name in rows:
        print("{}".format(name[0]))
        
        
def MeetFinalScore(conn_str):
    try:
        conn=psycopg2.connect(conn_str)
    except:
        print("I am unable to connect to the database")
        return;
    
    eventMeetName=input("Enter the name of the meet")
    eventMeetName=eventMeetName.strip()

    
    cur = conn.cursor()
    cur.callproc('Meet3', (eventMeetName, ))
    rows = cur.fetchall()
    # Make the changes to the database persistent
    conn.commit()

    # Close communication with the database
    cur.close()
    conn.close()
    
    print("\nMeet          Orgnization    Organization ID    Total Score")
    for meet_name, org_name, org_id, total_score in rows:
        print("{:<14}{:<15}{:<19}{}".format(meet_name, org_name, org_id,total_score))

def HeatSheetMeetMenu(conn_str):
    #
    selection= input("For What Meet do you want a heat sheet?\n")
    try:
        conn=psycopg2.connect(conn_str)
    except:
        print("I am unable to connect to the database")
        return;
    cur = conn.cursor()
    # cur.execute(querry)
    cur.callproc('MakeHeatSheetMeet4', (selection,))
    # Make the changes to the database persistent
    rows = cur.fetchall()
    conn.commit()
    #print("\nMeet           Event              Heat     Swimmer        School      Time     Rank")
    #for v in rows:
    #    printable_v = tuple((val if val is not None else '' for val in v))
    #    print("{:<15}{:<6}{:<15}{:<7}{:<15}{:<12}{:<9}{}".format(printable_v[0], printable_v[1], printable_v[2], printable_v[3], printable_v[4], printable_v[5], printable_v[6], printable_v[7]))
    print("\nMeet           Event                Heat   Swimmer    Participant ID  School    Time     Rank")
    for v in rows:
        printable_v = tuple((val if val is not None else '' for val in v))
        print("{:<15}{:<6}{:<15}{:<7}{:<15}{:<12}{:<9}{:<9}{}".format(printable_v[0], printable_v[1], printable_v[2], printable_v[3], printable_v[4], printable_v[5], printable_v[6], printable_v[7],printable_v[8]))

    cur.close()
    conn.close()
    
def HeatSheetParticipantMeetMenu(conn_str):
    #
    selection= input("For What Participant and Meet do you want a heat sheet?\n(use event id and meet name separate participant and meet with a comma)\n")
    vals=selection[:].split(",");
    vals=[x for x in vals if x]
    try:
        conn=psycopg2.connect(conn_str)
    except:
        print("I am unable to connect to the database")
        return;
    cur = conn.cursor()
    # cur.execute(querry)
    cur.callproc('MakeHeatSheetParticipantMeet5',vals)
    # Make the changes to the database persistent
    rows = cur.fetchall()
    conn.commit()

    print("\nMeet           Event                Heat   Swimmer    Participant ID  School    Time     Rank")
    for v in rows:
        printable_v = tuple((val if val is not None else '' for val in v))
        print("{:<15}{:<6}{:<15}{:<7}{:<15}{:<12}{:<9}{:<9}{}".format(printable_v[0], printable_v[1], printable_v[2], printable_v[3], printable_v[4], printable_v[5], printable_v[6], printable_v[7],printable_v[8]))

    cur.close()
    conn.close()

def HeatSheetSchoolMeetMenu(conn_str):
    #
    selection= input("For What School and Meet do you want a heat sheet? (separate school and meet with a comma)\n")
    vals=selection[:].split(",");
    vals=[x for x in vals if x]
    try:
        conn=psycopg2.connect(conn_str)
    except:
        print("I am unable to connect to the database")
        return;
    cur = conn.cursor()
    # cur.execute(querry)
    cur.callproc('MakeHeatSheetSchoolMeet4', tuple(vals))
    # Make the changes to the database persistent
    rows = cur.fetchall()
    conn.commit()
    #print("\nMeet           Event    Heat   Swimmer        School    Time     Rank")
    #    print("{:<15}{:<9}{:<7}{:<15}{:<12}{:<9}{}".format(meet, event, heat, swimmer, school, time, rank))
    #for v in rows:
    #    printable_v = tuple((val if val is not None else '' for val in v))
    #    print("{:<15}{:<6}{:<15}{:<7}{:<15}{:<12}{:<9}{}".format(printable_v[0], printable_v[1], printable_v[2], printable_v[3], printable_v[4], printable_v[5], printable_v[6], printable_v[7]))
    print("\nMeet           Event                Heat   Swimmer    Participant ID  School    Time     Rank")
    for v in rows:
        printable_v = tuple((val if val is not None else '' for val in v))
        print("{:<15}{:<6}{:<15}{:<7}{:<15}{:<12}{:<9}{:<9}{}".format(printable_v[0], printable_v[1], printable_v[2], printable_v[3], printable_v[4], printable_v[5], printable_v[6], printable_v[7],printable_v[8]))

    cur.close()
    conn.close()
    
def HeatSheetEventMeetMenu(conn_str):
    #
    selection= input("For What Event and Meet do you want a heat sheet? (use participant id, separate participant and meet with a comma)\n")
    vals=selection[:].split(",");
    vals=[x for x in vals if x]
    try:
        conn=psycopg2.connect(conn_str)
    except:
        print("I am unable to connect to the database")
        return;
    cur = conn.cursor()
    # cur.execute(querry)
    cur.callproc('MakeHeatSheetEventMeet',vals)
    # Make the changes to the database persistent
    rows = cur.fetchall()
    conn.commit()

    print("\nMeet           Event                Heat   Swimmer    Participant ID  School    Time     Rank (in heat)")
    for v in rows:
        printable_v = tuple((val if val is not None else '' for val in v))
        print("{:<15}{:<6}{:<15}{:<7}{:<15}{:<12}{:<9}{:<9}{}".format(printable_v[0], printable_v[1], printable_v[2], printable_v[3], printable_v[4], printable_v[5], printable_v[6], printable_v[7],printable_v[8]))

    cur.close()