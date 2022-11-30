#!/usr/bin/python3

### Birthday API Class
#
#   This class is designed to work with users' birthday dates inputs and outputs.
#
##
#   Available methods:
#   - getUserData     : Retrieve user birthday from DynamoDB.
#   - putUserData     : Retrieve user entry with birthday date into DynamoDB.
#   - validateRequest : Validate request payload.
#   - getDelta        : Return delta between two dates in days.
#
#   Author: Jevgenijs Migusa
#
###

import json
import boto3
import re as regex
import os
from datetime import date, datetime
import calendar

def lambda_handler(event, context):
    # Initiate Birthday Class
    birthday = Birthday()

    # Debugging part
    print("Printing event:")
    print(event)
    print("Printing context:")
    print(context)

    # Validate request
    if birthday.validateRequest(event) == False:
        return {
            "statusCode": 400,
            "body": "Invalid request."
        }

    # Extract method from the event
    method = event['httpMethod']

    # Extract username value from the event
    username = event['pathParameters']['username']

    # Act based on request method
    if method == "GET":
        return birthday.getUserData(username)
    elif method == "PUT":
        # python-lambda-local does not allow broken JSON files
        # event contains invalid JSON part in body..
        try:
            birthdayDate = json.loads(event['body'])['dateOfBirth']
        except:
            birthdayDate = event['body']['dateOfBirth']

        return birthday.putUserData(username, birthdayDate)

# Birthday Class
class Birthday:
    # Class initiation
    def __init__(self):
        self.dbTableName = os.environ['dynamo_table']
        self.env = os.environ['env']

        # Use local dynamodb for tests
        if self.env == "local":
            self.db = boto3.resource('dynamodb', endpoint_url='http://localhost:8000')
        else:
            self.db = boto3.resource('dynamodb')

        self.dbTable = self.db.Table(self.dbTableName)

        # Create local DynamoDB table if deos not exist
        if not self.dbTable:
            if self.env != "local":
                print("Missing DynamoDB table.")
            else:
                self.createDbTable()

        self.dateFormat = "%Y-%m-%d"
        self.todaysDate = date.today()

    # Get username data
    def getUserData(self, username):
        try:
            print("Checking for {} user in DynamoDB.".format(username))
            response = self.dbTable.get_item(TableName=self.dbTableName, Key={'username': username})['Item']
        except:
            print("Data is missing for user {}" .format(username))
            return {
                'statusCode': '404',
                'body': 'Data is missing for '+username+' user'
            }

        # Original date of birth
        birthdayDate = datetime.strptime(response['date'], self.dateFormat).date()

        # Modify for further comparison
        birthdayDate = birthdayDate.replace(year=self.todaysDate.year)

        # Get delta
        deltaInDays = self.getDelta(birthdayDate, self.todaysDate)

        if birthdayDate == self.todaysDate:
            message = "Hello, " + username + "! Happy birthday!"
        else:
            message = "Hello, " + username + "! Your birthday is in " + str(deltaInDays) + " days."

        return {
            'statusCode': '200',
            'body': message
        }

    # Get username data
    def putUserData(self, username, date):
        print("Inserting {}'s date of birth.".format(username))
        response = self.dbTable.put_item(TableName=self.dbTableName, Item={'username' : username,'date' : date})
        return {
            "statusCode": 204,
            "body": "No Content"
        }

    # Validate request payload
    def validateRequest(self, payload):
        try:
            print("Validating incoming request...")

            # Define validation regrex
            usernamePattern = "^([A-Za-z0-9])"
            birthdayPattern = self.dateFormat
            availableMethods = ["GET", "PUT"]

            method = payload['httpMethod']

            # Validate request method
            if method not in availableMethods:
                print("Invalid request method.")
                return False

            # Extract username value from the event
            username = payload['pathParameters']['username']

            # Validate username format
            if regex.match(usernamePattern, username) == False:
                print("Invalid username format.")
                return False

            if method == "PUT":
                # Extract date of birth from the event
                # python-lambda-local does not allow broken JSON files
                # event contains invalid JSON part in body..
                try:
                    birthday = json.loads(payload['body'])['dateOfBirth']
                except:
                    birthday = payload['body']['dateOfBirth']

                # Validate birthday date format
                try:
                    datetime.strptime(birthday, birthdayPattern)
                except:
                    print("Incorrect data format, should be YYYY-MM-DD")
                    return False

                # Verify if birthday date is not in the future.
                if self.todaysDate < datetime.strptime(birthday, self.dateFormat).date():
                    print("Hello, Kyle Reese.")
                    return False
        except:
            print("Something has gone wrong during request validation.")
            return False

        print("Request validation has been completed.")
        return True

    # Get delta for two dates
    def getDelta(self, date1, date2):
        # Return delta
        if date1 > date2:
            return abs((date1 - date2).days)
        else:
            return self.getDaysInYear(date1.year) - abs((date1 - date2).days)

    # Get days in given year
    def getDaysInYear(self, year):
        return 365 + calendar.isleap(year)

    # Create new DynamoDB table
    def createDbTable(self):
        self.db.create_table(
            AttributeDefinitions=[
                {
                    'AttributeName': 'username',
                    'AttributeType': 'S',
                }
            ],
            KeySchema=[
                {
                    'AttributeName': 'username',
                    'KeyType': 'HASH',
                }
            ],
            ProvisionedThroughput={
                'ReadCapacityUnits': 20,
                'WriteCapacityUnits': 20,
            },
            TableName=self.dbTableName,
        )

if __name__ == "__main__":
    event = []
    context = []
    lambda_handler(event, context)
