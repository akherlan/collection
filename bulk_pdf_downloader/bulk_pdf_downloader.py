#!/usr/bin/env python

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import pandas as pd
import requests
import time
import re
import os

# environment
DOWNLOADS_DIR = '/home/andi/Downloads/Paparan/'
CHROMEDRIVER_PATH = "/home/andi/opt/webdriver/chrome_97.0.4692.71/chromedriver"

# settings
os.chdir(DOWNLOADS_DIR)

# initial data (page 1)
driver = webdriver.Chrome(executable_path = CHROMEDRIVER_PATH)
driver.get("https://balitbanghub.dephub.go.id/kategori/materi-kegiatan")
time.sleep(2)

pdf_store = []
pdf_links = driver.find_elements_by_xpath('//*[@id="myTable"]/tbody/tr/td[6]/a')
for item in pdf_links:
  pdf_store.append(item.get_attribute("href"))

file_name = []
titles = driver.find_elements_by_xpath('//*[@id="myTable"]/tbody/tr/td[5]')
for item in titles:
  file_name.append(item.text)

speaker_name = []
speaker = driver.find_elements_by_xpath('//*[@id="myTable"]/tbody/tr/td[4]')
for item in speaker:
  speaker_name.append(item.text)

event_title = []
event = driver.find_elements_by_xpath('//*[@id="myTable"]/tbody/tr/td[3]')
for item in event:
  event_title.append(item.text)

event_date = []
date = driver.find_elements_by_xpath('//*[@id="myTable"]/tbody/tr/td[2]')
for item in date:
  event_date.append(item.text)

# more data (page 2 until n)
def check_table(driver):
  info = driver.find_element_by_id('myTable_info').text
  info = list(map(int, re.findall("\d+", info)))
  return(info)
info_table = check_table(driver)

wait = WebDriverWait(driver, 2)
while info_table[1] != info_table[2]:
  try:
    item_xpath = '//*[@id="myTable_next"]'
    item = wait.until(EC.visibility_of_element_located((By.XPATH, item_xpath)))
    driver.execute_script("arguments[0].click();", item)
    pdf_links = driver.find_elements_by_xpath('//*[@id="myTable"]/tbody/tr/td[6]/a')
    for item in pdf_links:
      pdf_store.append(item.get_attribute("href"))
    titles = driver.find_elements_by_xpath('//*[@id="myTable"]/tbody/tr/td[5]')
    for item in titles:
      file_name.append(item.text)
    speaker = driver.find_elements_by_xpath('//*[@id="myTable"]/tbody/tr/td[4]')
    for item in speaker:
      speaker_name.append(item.text)
    event = driver.find_elements_by_xpath('//*[@id="myTable"]/tbody/tr/td[3]')
    for item in event:
      event_title.append(item.text)
    date = driver.find_elements_by_xpath('//*[@id="myTable"]/tbody/tr/td[2]')
    for item in date:
      event_date.append(item.text)
    info_table = check_table(driver)
    time.sleep(3)
  except Exception:
    continue

driver.quit()

# downloading pdf files
for n in range(len(pdf_store)):
  pdf_resp = requests.get(pdf_store[n])
  fname = re.sub("\&", "dan", file_name[n])
  fname = "".join([c for c in fname if c.isalpha() or c.isdigit() or c==' ' or c=="-" or c=="(" or c==")"]).rstrip()
  with open(fname + ".pdf", "wb") as f:
    f.write(pdf_resp.content)
    time.sleep(3)

# save table
tbl_data = {
  "Tanggal" : event_date,
  "Kegiatan" : event_title,
  "Pemateri" : speaker_name,
  "Paparan" : file_name,
  "File" : pdf_store
}
tbl_data = pd.DataFrame(tbl_data)
tbl_data.to_csv("Katalog.csv", index = False)

