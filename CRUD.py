#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Apr 18 15:33:04 2017

@author: zhenshan
"""
import psycopg2

def ReadFile(filename, conn_str):
  #not sure if this is ok, or I have to maintain a list in sql
  #for now, do this.  I can switch to sql later.
  # Connect to an existing database


  valid_names  =["Org", "Meet", "Participant", "Event", "Stroke", "Distance", "Heat", "Swim", "Leg", "StrokeOf"]
  is_valid=False

  try:
      myfile = open(filename, "r")
  except IOError:
      print("Could not open file ")
      return;

  for line in myfile.readlines():

     if line.startswith("*"):
       vals=line[:-1].split(",");
       line=[x for x in vals if x]
       if (valid_names.count(line[0][1:])>0):
          is_valid=True
          table_name=line[0][1:]
       else:
          is_valid=False
     else:
        #check that the function name is valid first
        #if we don't have a real table name, don't bother
        if(is_valid):
          if((table_name=='Stroke')or (table_name=='Distance')or (table_name=='Leg'))  :
            vals=line[:-1].split(",");
            vals=[x for x in vals if x]
            #vals=line[:-1];
            callInsert(table_name, vals[0], conn_str)
          else:
              vals=line[:-1].split(",");
              vals=[x for x in vals if x]
              callInsert(table_name, vals, conn_str)

def ReadFileMenu(conn_str):
    selection= input("Please Input the file name")
    ReadFile(selection, conn_str)

def callInsert(table_name, arg_list, conn_str):
    valid_names  =["Org", "Meet", "Participant", "Event", "Stroke", "Distance", "Heat", "Swim", "Leg", "StrokeOf"]
    arg_count  =[3, 4, 3, 3,1 , 1, 3, 6, 1, 3]

    try:
        conn=psycopg2.connect(conn_str)
    except:
        print("I am unable to connect to the database")
        return;

    # Open a cursor to perform database operations
    cur = conn.cursor()
    if (table_name=="Org"):
       if(len(arg_list)!=3):
          print("Org requires 3 arguments:")
       else:
          cur.callproc('InsertOrg', (arg_list[0], arg_list[1], arg_list[2]))

    if (table_name=="Meet"):
        if(len(arg_list)!=4):
            print("Meet requires 4 arguments:")
        else:
            cur.callproc('InsertMeet', (arg_list[0], arg_list[1], arg_list[2], arg_list[3]))

    if (table_name=="Participant"):
        if(len(arg_list)!=4):
            print("Participant requires 4 arguments:")
        else:
            cur.callproc('InsertParticipant', (arg_list[0], arg_list[1], arg_list[2], arg_list[3]))

    if (table_name=="Event"):
        if(len(arg_list)!=3):
            print("Event requires 3 arguments:")
            print("X", arg_list, "X")
        else:
            cur.callproc('InsertEvent', (arg_list[0], arg_list[1], arg_list[2]))


    if (table_name=="Stroke"):
        #if(len(arg_list)!=1):
            #print("Stroke requires 1 arguments:")
        #else:
            cur.callproc('InsertStroke', (arg_list,))

    if (table_name=="Distance"):
        #if(len(arg_list)!=1):
        #    print("Distance requires 1 arguments:")
        #else:

            cur.callproc('InsertDistance', (int(arg_list),))

    if (table_name=="Heat"):
        if(len(arg_list)!=3):
            print("Heat requires 3 arguments:")
        else:
            cur.callproc('InsertHeat', (arg_list[0], arg_list[1], arg_list[2]))

    if (table_name=="Swim"):
        if(len(arg_list)!=6):
            print("Swim requires 6 arguments:")
        else:
            cur.callproc('InsertSwim', (arg_list[0], arg_list[1], arg_list[2], arg_list[3], int(arg_list[4]), float(arg_list[5])))

    if (table_name=="Leg"):
        #if(len(arg_list)!=1):
            #print("Leg requires 1 arguments:")
        #else:
            cur.callproc('InsertLeg', (int(arg_list),))

    if (table_name=="StrokeOf"):
        if(len(arg_list)!=3):
            print("StrokeOf requires 3 arguments:")
        else:
            cur.callproc('InsertStrokeOf', (arg_list[0], arg_list[1], arg_list[2]))


    conn.commit()

    # Close communication with the database
    cur.close()
    conn.close()

def AddRowMenu(conn_str):
    valid_names  =["Org", "Meet", "Participant", "Event", "Stroke", "Distance", "Heat", "Swim", "Leg", "StrokeOf"]
    name_not_valid=True
    while(name_not_valid):
        selection= input("What Table Do You Want to Add A Row to?\n(Org, Meet, Participant, Event, Stroke, Distance, Heat, Swim, Leg, StrokeOf)\n")
        print("read in:", selection)
        #make sure the name is valid
        if(valid_names.count(selection)>0):
            name_not_valid=False
            table_name=selection
    #get the available tables from the database
    # Connect to an existing database
    # Connect to an existing database
    try:
        conn=psycopg2.connect(conn_str)
    except:
        print("I am unable to connect to the database")
        return;
    querry="SELECT reminder FROM  Remind WHERE tablename='"+ table_name+"'"
    cur = conn.cursor()
    cur.execute(querry)
    # Make the changes to the database persistent
    rows = cur.fetchall()
    conn.commit()
    # Close communication with the database
    cur.close()
    conn.close()
    #should only be 1 row, but I'm itterating to get at it.
    print("Insert the fields separated by commas [,] .  Use NULL in place of a field to omit it.")
    for r in rows:
        print (r[0])
    selection=input()
    vals=selection[:-1].split(",");
    vals=[x for x in vals if x]
    if((table_name=='Stroke')or (table_name=='Distance')or (table_name=='Leg'))  :
        #vals=line[:-1];
        callInsert(table_name, vals[0])
    else:
        callInsert(table_name, vals)
        
def ChangeRowMenu(conn_str):
      valid_names  =["Org", "Participant", "Event"]
      name_not_valid=True
      while(name_not_valid):
         selection= input("What Table Do You Want to Change?\n(Org, Participant, Event)\n")
         #print("read in:", selection)
         #make sure the name is valid
         if(valid_names.count(selection)>0):
            name_not_valid=False
            table_name=selection
      #get the available tables from the database
      # Connect to an existing database
      # Connect to an existing database
      try:
          conn=psycopg2.connect(conn_str)
      except:
          print("I am unable to connect to the database")
          return;
     # querry="SELECT reminder FROM  RemindPrimaryKey WHERE TableName='"+ table_name+"'"
      cur = conn.cursor()
     # cur.execute(querry)
      cur.callproc('GetPrimaryKey', (table_name,  ))
      # Make the changes to the database persistent
      rows = cur.fetchall()
      conn.commit()

      for r in rows:
          primary_key= (r[0])
      print("Update will be based on primary_key:", primary_key)
      #should only be 1 row, but I'm itterating to get at it.
      print("Enter primary key:")
      selection=input()
      #make sure primary key exists
      #MAKE SURE PRIMARY KEY IS VALID!!!!!

      cur = conn.cursor()
      cur.callproc('GetNotPrimaryKey', (table_name,  ))
      # Make the changes to the database persistent
      rows = cur.fetchall()
      conn.commit()
      # Close communication with the database
      cur.close()
      conn.close()
      #should only be 1 row, but I'm itterating to get at it.
      print("Insert the fields separated by commas [,] .  Use NULL in place of a field to omit it.")
      for r in rows:
          print (r[0])

      selection=input()
      #arg_list=selection.split(",")
      vals=selection[:-1].split(",");
      vals=[x for x in vals if x]
      vals.insert(0, table_name )
      callInsert(table_name, vals)
      #callInsert(table_name, arg_list)

def UpdateRowMenu(conn_str):
    valid_names  =["Org", "Participant", "Event"]
    selection= input("What Table Do You Want to Update\n(Org, Participant, Event)\n")
    #make sure the name is valid
    if(valid_names.count(selection)>0):
       name_not_valid=False
       table_name=selection
       UpdateRow(table_name, conn_str)
    else:
        print ("Table not valid:")

def UpdateRow(table_name, conn_str):
    #get the available tables from the database
    # Connect to an existing database
    # Connect to an existing database
    try:
        conn=psycopg2.connect(conn_str)
    except:
        print("I am unable to connect to the database")
        return;
    querry="SELECT reminder FROM  RemindPrimaryKey WHERE tablename='"+ table_name+"'"
    cur = conn.cursor()
    cur.execute(querry)
    rows = cur.fetchall()
    # Make the changes to the database persistent
    conn.commit()
    #should only be 1 row, but I'm itterating to get at it.
    print("Enter primary key:")
    for r in rows:
        print (r[0])
    selection=input()
    #now ask for values to update
    querry="SELECT reminder FROM  RemindNotPK WHERE tablename='"+ table_name+"'"
    #querry="SELECT reminder FROM  Remind WHERE tablename='"+ table_name+"'"
    cur = conn.cursor()
    cur.execute(querry)
    rows = cur.fetchall()
    # Make the changes to the database persistent
    conn.commit()

    print("Enter a Field_Name='New_Value' .  Separate multiple Fields by commas.  Valid fields:")
    for r in rows:
        print (r[0])
    selection=input()
    arg_list=selection.split(", ")
    print("arg list:", arg_list)
    #callInsert(table_name, arg_list)
    # Close communication with the database
    cur.close()
    conn.close()

def OutputTable(conn_str):
    '''Output the specified table as .csv'''
    # Connect to an existing database
    tableList  =['Org', "Meet", "Participant", "Leg", "Stroke", "Distance", "Event", "StrokeOf", "Heat", "Swim"]

#    selection= input("What Tables Do You Want to Output? Please list all of them and seperate each table by ',' without space. \n(Org, Meet, Participant, Event, Stroke, Distance, Heat, Swim, Leg, StrokeOf)\n")
#    tableList = selection.split(',')
    outputTableDList = []
    fileName= input("What is the name for file (without .csv)")
#    outputPath = "output/output.csv"

    
    try:
        conn = psycopg2.connect(conn_str)
        print("Opened database successfully")
    except:
        print("I am unable to connect to the database")
    
    # Open a cursor to perform database operations
    cur = conn.cursor()
    
    for tblName in tableList:
        if tblName == 'Org':
            cur.callproc('OutputOrg')
            rows = cur.fetchall()
            outputTableDList.append(rows)
        
        if tblName == 'Meet':
            cur.callproc('OutputMeet')
            rows = cur.fetchall()
            outputTableDList.append(rows)
        
        if tblName == 'Participant':
            cur.callproc('OutputParticipant')
            rows = cur.fetchall()
            outputTableDList.append(rows)
        
        if tblName == 'Event':
            cur.callproc('OutputEvent')
            rows = cur.fetchall()
            outputTableDList.append(rows)
        
        if tblName == 'Stroke':
            cur.callproc('OutputStroke')
            rows = cur.fetchall()
            outputTableDList.append(rows)
        
        if tblName == 'Distance':
            cur.callproc('OutputDistance')
            rows = cur.fetchall()
            outputTableDList.append(rows)
        
        if tblName == 'Heat':
            cur.callproc('OutputHeat')
            rows = cur.fetchall()
            outputTableDList.append(rows)
        
        if tblName == 'Swim':
            cur.callproc('OutputSwim')
            rows = cur.fetchall()
            outputTableDList.append(rows)
        
        if tblName == 'Leg':
            cur.callproc('OutputLeg')
            rows = cur.fetchall()
            outputTableDList.append(rows)
        
        if tblName == 'StrokeOf':
            cur.callproc('OutputStrokeOf')
            rows = cur.fetchall()
            outputTableDList.append(rows)
    # Make the changes to the database persistent
    conn.commit()
    
    # Close communication with the database
    cur.close()
    conn.close()
    
    try:
        with open(fileName + '.csv', 'w') as fp:
            for tblNameIdx, tblData in enumerate(outputTableDList):
                fp.write("*%s\n"%tableList[tblNameIdx])
                size = len(tblData[0])
                formatStr = ",".join(['%s' for i in range(size)])
                fp.write('\n'.join(formatStr % tuple([y if not isinstance(y, bool) else int(y) for y in x]) for x in tblData))
                fp.write('\n')
    except:
        with open(fileName + '.csv', 'w') as fp:
            fp.write("")
        print("Empty query, output an empty .csv file")
        
