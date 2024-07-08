import pandas as pd
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException, StaleElementReferenceException
from bs4 import BeautifulSoup
import time
import json
import os
from webdriver_manager.chrome import ChromeDriverManager

class ContractParser:
    """
    A class to parse contract information from a given URL 
    and save it to an Excel file.
    
    """

    def __init__(self, url, output_file):
        """
        Initializes the ContractParser with the given URL and output file.

        :param url: URL of the webpage to parse.
        :param output_file: Name of the Excel file to save the data.
        """
        self.url = url
        self.output_file = output_file
        self.data = []
        self.setup_driver()

    def setup_driver(self):
        """
        Sets up the Chrome WebDriver with specified options.
        """
        options = webdriver.ChromeOptions()
        options.add_argument("start-maximized")  # Start the browser maximized
        options.add_argument('disable-infobars')  # Disable the info bar
        service = Service(ChromeDriverManager().install())
        self.driver = webdriver.Chrome(service=service, options=options)


    def close_modal(self):
        """
        Closes any modal pop-ups that appear on the webpage.
        """
        try:
            close_button = WebDriverWait(self.driver, 0.5).until(
                EC.visibility_of_element_located((By.CSS_SELECTOR, '.close'))
            )
            close_button.click()
        except TimeoutException:
            print("Modal did not appear or close button not found")

    def parse_table(self):
        """
        Parses the table on the webpage and extracts the data.
        Elements to find are given by inspecting the HTML code in the webpage.
        """
        soup = BeautifulSoup(self.driver.page_source, 'lxml')
        table = soup.find("table", {"id": "iddatatable"}).find("tbody")
        rows = table.find_all('tr')

        for row in rows:
            cols = row.find_all('td')
            cols_text = [col.text for col in cols]
            self.data.append(cols_text)

    def click_next(self):
        """
        Clicks the 'Next' button to navigate to the next page of the table.

        :return: True if the 'Next' button was clicked 
        and a new page was loaded, False otherwise.
        """
        try:
            next_button = self.driver.find_element(By.CSS_SELECTOR, 
                                                   "#iddatatable_next")
            if next_button.is_enabled():
                html_before_click = self.driver.page_source
                next_button.click()
                time.sleep(0.5)  
                html_after_click = self.driver.page_source
                if html_before_click == html_after_click:
                    return False
            else:
                return False
        except (TimeoutException, StaleElementReferenceException):
            return False
        return True

    def parse(self):
        """
        Parses the entire table across all pages 
        and saves the data to an Excel file.
        """
        self.driver.get(self.url)
        while True:
            self.close_modal()  
            self.parse_table()  
            if not self.click_next():  
                break
        self.driver.quit()
        self.save_to_excel()

    def save_to_excel(self):
        """
        Saves the extracted data to an Excel file.
        """
        df = pd.DataFrame(self.data)
        df.to_excel(self.output_file, index=False)
        print(f"Data saved to {self.output_file}")

def load_config(config_path):
    """
    Loads the configuration from a JSON file.

    :param config_path: Path to the configuration file.
    :return: Configuration dictionary.
    """
    with open(config_path, 'r') as file:
        config = json.load(file)
    return config

if __name__ == "__main__":
    config_path = os.path.join(os.path.dirname(__file__), 'config.json')
    config = load_config(config_path)
    urls_and_outputs = config['urls_and_outputs']

    for entry in urls_and_outputs:
        url = entry['url']
        output = entry['output_file']
        parser = ContractParser(url, output)
        parser.parse()
