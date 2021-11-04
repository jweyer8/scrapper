from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
import re

#wait for page to load
def waitForLoad():
    WebDriverWait(driver=driver, timeout=10).until(lambda x: x.execute_script("return document.readyState === 'complete'"))


#get input from user
#for future use... not currently necessary
#could read from text file for this
def getUserInput():
    # credentials
    # proly not great security wise...
    global LinkedInusername
    LinkedInusername = 'jweyer@zagmail.gonzaga.edu'
    global LinkedInpassword
    LinkedInpassword = 'Jw662607004'


#get the relevant job notifications
def getJobNotificationURLs():
    jobNotifications = driver.find_elements_by_tag_name("article")
    jobNotificationURLs = []
    relevantNotificationPattern =  re.compile(".*" + "/jobs/search" + ".*")
    for jobNotification in jobNotifications:
        url = jobNotification.find_element_by_tag_name("a").get_attribute("href")
        if(relevantNotificationPattern.match(url)):
            #add experience level
            #Entry level -> E = 2
            url.replace("alertAction=viewjobs","f_E=2")
            jobNotificationURLs.append(url)

    return jobNotificationURLs



# find individual jobs #
def getJobs():
    #get all job urls
    jobs = driver.find_elements_by_xpath("//ul[@class='jobs-search-results__list list-style-none']/li/div/div/div/div/a")
    urls = []
    for job in jobs:
        typePattern = re.compile(".*" + "(Manufacturing|Technichian|Senior|Manager|Materials|Mid|II|III|IV|Sr.)" + ".*", re.IGNORECASE)
        if(not typePattern.match(job.text)):
            urls.append(job.get_attribute("href"))

    #determine if the job meets requirements
    for url in urls:
        driver.get(url)
        waitForLoad()
        driver.find_element_by_xpath("//button[@aria-label='Click to see more description']").click()
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        waitForLoad()
        displayFits()

#display all relevant job info
def displayFits():
    description = driver.find_element_by_tag_name("article")
    experiencePattern = re.compile("([\d]+[\s]?[-][\s]?[\d]+|[\d]+)" + ".*" + "experience")
    listItems = description.find_elements_by_tag_name("li")
    for listItem in listItems:
        match2 = experiencePattern.match(listItem.text)
        if(match2):
            if(int(re.compile("[\d]+").match(match2.group(0)).group(0)) <= 1):
                print(driver.find_element_by_xpath("//div[@class='job-view-layout jobs-details']/div/div/div/div/div/h1").text)
                print(driver.current_url + "\n")

    driver.back()


###################################################
#                    MAIN                         #
###################################################

# initialize driver #
driver = webdriver.Chrome(r'C:\Users\jweye\PycharmProjects\pythonProject\snag\chromedriver.exe')
driver.maximize_window()

#get user input
getUserInput()

# sign in #
driver.get('https://www.linkedin.com/login')
driver.find_element_by_id('username').send_keys(LinkedInusername)
driver.find_element_by_id('password').send_keys(LinkedInpassword)
driver.find_element_by_tag_name("button").click()
waitForLoad()

# get jobs from notificaion section#
driver.get('https://www.linkedin.com/notifications')
waitForLoad()

# go through all relevant notifications
notifications = getJobNotificationURLs()
for notification in notifications:
    driver.get(notification)
    waitForLoad()
    #find jobs in the specific notification
    getJobs()

#driver.close()









