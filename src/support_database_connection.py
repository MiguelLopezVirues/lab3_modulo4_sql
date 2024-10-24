
# database agent
import psycopg2
from psycopg2 import OperationalError, errorcodes, errors

def connect_to_database(database, credentials_dict):
    try:
        # define connection
        conexion = psycopg2.connect(
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


    return conexion

def connect_and_query(database, credentials_dict, query):

    # establish connection
    connection = connect_to_database(database, credentials_dict)
    cursor = connection.cursor()

    # launch query
    cursor.execute(query)
    result_df = cursor.fetchall()

    # close connection
    cursor.close()
    connection.close()
    
    return result_df