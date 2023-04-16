import numpy as np
from selenium import webdriver
from webdriver_manager.chrome import ChromeDriverManager
from time import sleep
import random
import pandas as pd
from selenium.common.exceptions import NoSuchElementException, ElementNotInteractableException
from selenium.webdriver.common.by import By
import requests


def crawl_link(driver,new_link):
    link = driver.find_element('xpath',new_link)
    x = link.find_elements(By.CSS_SELECTOR,'.table-chart [href]')
    links = [link.get_attribute("href") for link in x]
    text = [x.text for x in x]
    index = np.arange(1,len(links)+1)
    df1 = pd.DataFrame(list(zip(index,text,links)),columns=['Idx','Majoring', 'Links'])
    df1.to_csv('D:\chungkhoan\Majoring.csv',index=False)
    return df1

def get_data(number,dem,idx,Stock_code,Name_company,Industry,ExChange,KLCPNY ,Major ):
    for i in range(3,number+3):
        index = driver.find_element('xpath',idx_data.format(i))
        idx.append(int(index.text))

        stock_code = driver.find_element('xpath',Stock_code_data.format(i))
        Stock_code.append(stock_code.text)

        name_company = driver.find_element('xpath',Name_data.format(i))
        Name_company.append(name_company.text)

        industry = driver.find_element('xpath',Industry_data.format(i))
        Industry.append(industry.text)

        exchange = driver.find_element('xpath',Exchange_data.format(i))
        ExChange.append(exchange.text)

        klckpny = driver.find_element('xpath',KLCPNY_data.format(i))
        KLCPNY.append(klckpny.text)

        Major.append(Majoring[dem])
    return idx,Stock_code,Name_company,Industry,ExChange,KLCPNY,Major


def crawl_data_company():
    url = 'https://api-dulieu.mbs.com.vn/api/OverviewMarket/GetAutoCompleteCompanyAndIndex?languageId=1'
    reponse = requests.get(url)
    data = reponse.json()
    data = data['Data']
    id , CompanyCode, FullName, CompanyID, CatID = [] , [], [], [], []
    result = get_data_company(data,id , CompanyCode, FullName, CompanyID, CatID)
    column = ['Index', 'Company Code', 'Full_Name', 'Company_ID','CatID']
    df = pd.DataFrame(list(zip(id , CompanyCode, FullName, CompanyID, CatID)),columns = column)
    df.to_csv('D:\chungkhoan\Company.csv',index=False)
    return df

def get_data_company(data,id , CompanyCode, FullName, CompanyID, CatID):
    for i in range(len(data)):
        small_data = data[i]
        for key,values in dict.items(small_data):
            if key == '$id': id.append((int(values)-1))
            if key == 'CompanyCode': CompanyCode.append(values)
            if key == 'FullName': FullName.append(values)
            if key == 'CompanyID': CompanyID.append(values)
            if key == 'CatID': CatID.append(values)


def load_data(idx,Stock_code,Name_company,Industry,ExChange,KLCPNY,Major):
    columns = ['Number','Stock_code', 'Name_Company','Industry','Exchange','KL_CPNY_(CP)','Majority']
    df = pd.DataFrame(list(zip(idx,Stock_code,Name_company,Industry,ExChange,KLCPNY,Major)),columns=columns)
    df.to_csv('D:\chungkhoan\data.csv',index=False)

def crawl_data():
    dem = 0
    idx,Stock_code,Name_company,Industry,ExChange,KLCPNY ,Major = [], [] , [], [] , [], [] , []
    for link in links:
        driver.get(link)
        try:
            print("Prepare get data {} ! ".format(Majoring[dem]))
            number = driver.find_element('xpath','/html/body/div[1]/div[2]/div[2]/div[3]/div[1]/span')
            number = int(number.text)
            idx, Stock_code,Name_company,Industry,ExChange,KLCPNY,Major = get_data(number,dem,idx,Stock_code,Name_company,Industry,ExChange,KLCPNY ,Major )
            print("Get data {} is success ! ".format(Majoring[dem]))
            dem+=1
            sleep(random.randint(1,3))
        except:
            print("Get data {} fail ! ",format(Majoring[dem]))
            dem+=1
    load_data(idx,Stock_code,Name_company,Industry,ExChange,KLCPNY,Major)


if __name__ == '__main__':
    driver = webdriver.Chrome(ChromeDriverManager().install())
    url = 'https://dulieu.mbs.com.vn/vi/OverviewMarket'
    new_link = '/html/body/div[1]/div[2]/div[2]/div[3]/div[1]/div[1]/div'
    driver.get(url)

    #Get all links data
    df = crawl_link(driver,new_link)

    #Get each linked and major line of data
    links = []
    Majoring = []
    for link in df['Links']:
        links.append(link)
    for major in df['Majoring']:
        Majoring.append(major)

    #Link của từng loại dữ liệu
    idx_data = '/html/body/div[1]/div[2]/div[2]/div[3]/div[3]/table/tbody/tr[{}]/td[1]'
    Stock_code_data = '/html/body/div[1]/div[2]/div[2]/div[3]/div[3]/table/tbody/tr[{}]/td[2]'
    Name_data = '/html/body/div[1]/div[2]/div[2]/div[3]/div[3]/table/tbody/tr[{}]/td[3]'
    Industry_data = '/html/body/div[1]/div[2]/div[2]/div[3]/div[3]/table/tbody/tr[{}]/td[4]'
    Exchange_data = '/html/body/div[1]/div[2]/div[2]/div[3]/div[3]/table/tbody/tr[{}]/td[5]'
    KLCPNY_data = '/html/body/div[1]/div[2]/div[2]/div[3]/div[3]/table/tbody/tr[{}]/td[6]'

    crawl_data()
    crawl_data_company()

