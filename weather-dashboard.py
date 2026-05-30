# ============================================
# Weather Dashboard CLI Tool
# Author: Vikrant Verma
# Description: Real-time weather forecast
# using OpenWeatherMap API with alerts
# ============================================

import requests
import json
from datetime import datetime

API_KEY = "your_api_key_here"
BASE_URL = "https://api.openweathermap.org/data/2.5"

def get_weather(city):
    url = f"{BASE_URL}/weather?q={city}&appid={API_KEY}&units=metric"
    response = requests.get(url)
    return response.json()

def get_forecast(city):
    url = f"{BASE_URL}/forecast?q={city}&appid={API_KEY}&units=metric"
    response = requests.get(url)
    return response.json()

def display_current_weather(data):
    print("\n" + "="*50)
    print(f"  WEATHER REPORT - {data['name']}, {data['sys']['country']}")
    print("="*50)
    print(f"  Condition   : {data['weather'][0]['description'].title()}")
    print(f"  Temperature : {data['main']['temp']}°C")
    print(f"  Feels Like  : {data['main']['feels_like']}°C")
    print(f"  Humidity    : {data['main']['humidity']}%")
    print(f"  Wind Speed  : {data['wind']['speed']} m/s")
    print(f"  Visibility  : {data.get('visibility', 'N/A')} m")
    print("="*50)

def display_forecast(data):
    print("\n  5-DAY FORECAST")
    print("-"*50)
    seen_dates = []
    for item in data['list']:
        date = item['dt_txt'].split(" ")[0]
        if date not in seen_dates:
            seen_dates.append(date)
            temp = item['main']['temp']
            desc = item['weather'][0]['description'].title()
            print(f"  {date}  |  {temp}°C  |  {desc}")
    print("-"*50)

def check_alerts(data):
    temp = data['main']['temp']
    wind = data['wind']['speed']
    print("\n  WEATHER ALERTS")
    print("-"*50)
    if temp > 40:
        print("  ⚠️  EXTREME HEAT WARNING: Stay hydrated!")
    elif temp < 5:
        print("  ⚠️  COLD ALERT: Risk of frost conditions!")
    if wind > 15:
        print("  ⚠️  HIGH WIND ALERT: Avoid outdoor activities!")
    humidity = data['main']['humidity']
    if humidity > 85:
        print("  ⚠️  HIGH HUMIDITY: Uncomfortable conditions!")
    if temp <= 40 and wind <= 15 and humidity <= 85:
        print("  ✅  No severe weather alerts.")
    print("-"*50)

def main():
    print("\n  🌤  WEATHER FORECAST DASHBOARD")
    print("  By Vikrant Verma - IT Operations\n")
    city = input("  Enter city name: ")
    
    print(f"\n  Fetching weather data for {city}...")
    
    current = get_weather(city)
    forecast = get_forecast(city)
    
    if current.get("cod") != 200:
        print(f"\n  ❌ Error: {current.get('message', 'City not found')}")
        return
    
    display_current_weather(current)
    check_alerts(current)
    display_forecast(forecast)
    
    print("\n  Data fetched at:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

if __name__ == "__main__":
    main()
