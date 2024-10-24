
# database agent
import psycopg2
from psycopg2 import OperationalError, errorcodes, errors

# data processing
import pandas as pd

def connect_to_database(database, credentials_dict):

    try:
        # define connection
        connection = psycopg2.connect(
            database = database,
            user = credentials_dict["username"],
            password =  credentials_dict["password"],
            host="localhost",
            port="5432" 
        )


    except OperationalError as e:

        if e.pgcode == errorcodes.INVALID_PASSWORD:
            print("La contraseña es erronea")

        elif e.pgcode == errorcodes.CONNECTION_EXCEPTION:
            print("Error de conexión.")

        else:
            print(f"Ocurrio el error {e}",e.pgcode)


    return connection

def connect_and_query(database, credentials_dict, query, columns = None):

    # establish connection
    connection = connect_to_database(database=database, credentials_dict=credentials_dict)
    cursor = connection.cursor()

    # launch query
    cursor.execute(query)

    # take column names from query or user input
    if columns == "query":
        columns = [desc[0] for desc in cursor.description]
    elif not isinstance(columns, list):
        columns = None

    result_df = pd.DataFrame(cursor.fetchall(), columns=columns)

    # close connection
    cursor.close()
    connection.close()
    
    return result_df