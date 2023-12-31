#install the packages
install.packages("tidyverse")
install.packages("lubridate")
install.packages("hms")
install.packages("janitor")
install.packages("readr")
install.packages("data.table")
install.packages("ggplot2")
install.packages("dplyr")
#load libraries needed to manipulate the data
library("tidyverse")
library("lubridate")
library("hms")
library("janitor")
library("readr")
library("data.table")
library("ggplot2")
library("dplyr")
#import the CSV files to R, we use the function read_csv, and change the names for the tables 
getwd()
setwd("/Users/macbook")
q1_2018 <- read_csv("Divvy_Trips_2018_Q1.csv")
q2_2018 <- read_csv("Divvy_Trips_2018_Q2.csv")
q3_2018 <- read_csv("Divvy_Trips_2018_Q3.csv")
q4_2018 <- read_csv("Divvy_Trips_2018_Q4.csv")

#check if the column names in each file are the same, and not mandatory to be in the same order
colnames(q1_2018)
colnames(q2_2018)
colnames(q3_2018)
colnames(q4_2018)

#inspect the dataframes and look for inconguencies
str(q1_2018)
str(q4_2018)
str(q3_2018)
str(q2_2018)

#rename columns  to make them consisent
  q1_2018 <- rename(q1_2018, "trip_id"="01 - Rental Details Rental ID", start_time="01 - Rental Details Local Start Time", end_time="01 - Rental Details Local End Time",  bikeid="01 - Rental Details Bike ID", tripduration="01 - Rental Details Duration In Seconds Uncapped", from_station_id="03 - Rental Start Station ID",
  from_station_name="03 - Rental Start Station Name", to_station_id="02 - Rental End Station ID", to_station_name="02 - Rental End Station Name", usertype="User Type", gender="Member Gender", birthyear="05 - Member Details Member Birthday Year")
  
#combine individual quarter's data frames into one big data frame
all_trips <- rbind(q1_2018, q2_2018, q3_2018, q4_2018)

#remove the Gender and Birthyear
all_trips <- subset(all_trips, select=-c(gender, birthyear))

#clean and remove the spaces, etc in the table
all_trips <- clean_names(all_trips)
remove_empty(all_trips, which=c())

#inspect the new table that has been created
colnames(all_trips)  #List of column names
nrow(all_trips)  #How many rows are in data frame?
dim(all_trips)  #Dimensions of the data frame?
head(all_trips)  #See the first 6 rows of data frame.  Also tail(qs_raw)
str(all_trips)  #See list of columns and data types (numeric, character, etc)
summary(all_trips)  #Statistical summary of data. Mainly for numerics

#add columns that list the hour, date, month, day and year of each ride for further information
all_trips$date <- as.Date(all_trips$start_time)
all_trips$month <- format(as.Date(all_trips$start_time), "%m")
all_trips$day <- format(as.Date(all_trips$date), "%d")
all_trips$year <- format(as.Date(all_trips$date), "%Y")
all_trips$day_of_week <- format(as.Date(all_trips$date), "%A")
all_trips$starting_hour <- format(as.POSIXct(all_trips$start_time), '%H')

#add a "ride_length" calculation to all_trips (in seconds)
all_trips$ride_length <- difftime(all_trips$end_time,all_trips$start_time, units ='sec')

#inspect the structure of the columns
str(all_trips)

# Remove "bad" data
# The dataframe includes a few hundred entries when bikes were taken out of docks and checked for quality by Divvy or ride_length was negative
# We will create a new version of the dataframe (v2) since data is being removed
all_trips_v2 <- all_trips[!(all_trips$ride_length<=0),]

#descriptive analysis on ride_length (all figures in seconds)
mean(all_trips_v2$ride_length) #straight average (total ride length / rides)
median(all_trips_v2$ride_length) #midpoint number in the ascending array of ride lengths
max(all_trips_v2$ride_length) #longest ride
min(all_trips_v2$ride_length) #shortest ride

#or we can condense the four lines above to one line using summary() on the specific attribute
summary(all_trips_v2$ride_length)


#compare members and casual users
aggregate(all_trips_v2$ride_length ~ all_trips_v2$usertype, FUN = mean)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$usertype, FUN = median)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$usertype, FUN = max)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$usertype, FUN = min)

#we can clearly see that casual customers almost spend double the amount of time using the bikes as compared to subscribers!

#total number of rides
nrow(all_trips_v2)

#usertype count
all_trips_v2 %>%
  group_by(usertype) %>% 
  count(usertype)

#total trip duration by usertype
aggregate(all_trips_v2$ride_length ~ all_trips_v2$usertype, FUN = sum)
#or use this instead
all_trips_v2 %>% 
  group_by(usertype) %>%
  summarise(total_duration = sum(ride_length))

#see the average ride time by each day for members vs casual users
aggregate(all_trips_v2$ride_length ~ all_trips_v2$usertype + all_trips_v2$day_of_week, FUN = mean)
#or use this instead:
all_trips_v2 %>% 
  group_by(usertype, day_of_week) %>%
  summarise(average_duration = mean(ride_length)) %>% 
  arrange(day_of_week)

#notice that the days of the week are out of order. Let's fix that.
all_trips_v2$day_of_week <- ordered(all_trips_v2$day_of_week, levels=c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"))

#average ride length for user by months
all_trips_v2 %>% 
  group_by(month, usertype) %>%
  summarise(average_duration = mean(ride_length))

#analyze ridership data by type and weekday, and first create new colums for the day of the week
all_trips_v2$what_day_of_week <- wday(all_trips_v2$start_time) 

#let's visualize the number of rides by rider type
ggplot(data = all_trips_v2) +
  aes(x = day_of_week, fill = usertype) +
  geom_bar(position = 'dodge') +
  labs(x = 'Day of week', y = 'Number of rides', fill = 'Member type', title = 'Number of rides by member type')

#visualize the hourly use of bikes in a week 
ggplot(data = all_trips_v2) +
  aes(x = starting_hour, fill = usertype) +
  facet_wrap(~day_of_week) +
  geom_bar() +
  labs(x = 'Starting hour', y = 'Number of rides', fill = 'Member type', title = 'Hourly use of bikes throughout the week') +
  theme(axis.text = element_text(size = 3))

#find out the most popular start stations for our subscribers and customers
all_trips_v2 %>% 
  group_by(from_station_name, usertype) %>% 
  count(from_station_name, sort=T) %>% 
  filter(usertype== "Subscriber") 


all_trips_v2 %>% 
  group_by(from_station_name, usertype) %>% 
  count(from_station_name, sort=T) %>% 
  filter(usertype== "Customer")
       
#find out the most popular end stations for our subscribers and customers
all_trips_v2 %>% 
  group_by(to_station_name, usertype) %>% 
  count(to_station_name, sort=T) %>% 
  filter(usertype== "Subscriber") 


all_trips_v2 %>% 
  group_by(to_station_name, usertype) %>% 
  count(to_station_name, sort=T) %>% 
  filter(usertype== "Customer")

#save the data for visualization purpose
data_mean <- aggregate(all_trips_v2$ride_length ~ all_trips_v2$usertype, FUN = mean)  
write.csv(data_mean, file = "/Users/macbook/Documents/Data/Project_2_Cyclist/avg_ride_length.csv",row.names=FALSE)

data_median <- aggregate(all_trips_v2$ride_length ~ all_trips_v2$usertype, FUN = median)
write.csv(data_median, file = "/Users/macbook/Documents/Data/Project_2_Cyclist/median_ride_length.csv",row.names=FALSE)

data_number_of_usertype <- (all_trips_v2 %>%
  group_by(usertype) %>% 
  count(usertype))
write.csv(data_number_of_usertype, file = "/Users/macbook/Documents/Data/Project_2_Cyclist/data_number_of_usertype.csv",row.names=FALSE)

average_ride_time_each_day <- aggregate(all_trips_v2$ride_length ~ all_trips_v2$usertype + all_trips_v2$day_of_week, FUN = mean)
write.csv(average_ride_time_each_day, file = "/Users/macbook/Documents/Data/Project_2_Cyclist/average_ride_time_each_day.csv",row.names=FALSE)

trip_duration_by_usertype <- aggregate(all_trips_v2$ride_length ~ all_trips_v2$usertype, FUN = sum)
write.csv(trip_duration_by_usertype, file = "/Users/macbook/Documents/Data/Project_2_Cyclist/trip_duration_by_usertype.csv",row.names=FALSE)

from_station_name_subscriber <- (all_trips_v2 %>% 
  group_by(from_station_name, usertype) %>% 
  count(from_station_name, sort=T) %>% 
  filter(usertype== "Subscriber"))
write.csv(from_station_name_subscriber, file = "/Users/macbook/Documents/Data/Project_2_Cyclist/from_station_name_subscriber.csv",row.names=FALSE)

from_station_name_customer <- (all_trips_v2 %>% 
  group_by(from_station_name, usertype) %>% 
  count(from_station_name, sort=T) %>% 
  filter(usertype== "Customer"))
write.csv(from_station_name_customer, file = "/Users/macbook/Documents/Data/Project_2_Cyclist/from_station_name_customer.csv",row.names=FALSE)

end_station_name_subscriber <- (all_trips_v2 %>% 
  group_by(to_station_name, usertype) %>% 
  count(to_station_name, sort=T) %>% 
  filter(usertype== "Subscriber"))
write.csv(end_station_name_subscriber, file = "/Users/macbook/Documents/Data/Project_2_Cyclist/end_station_name_subscriber.csv",row.names=FALSE)

end_station_name_customer <- (all_trips_v2 %>% 
                                group_by(to_station_name, usertype) %>% 
                                count(to_station_name, sort=T) %>% 
                                filter(usertype== "Customer"))
write.csv(end_station_name_customer, file = "/Users/macbook/Documents/Data/Project_2_Cyclist/end_station_name_customer.csv",row.names=FALSE)

avr_by_month <- (all_trips_v2 %>% 
  group_by(month, usertype) %>%
  summarise(average_duration = mean(ride_length)))
write.csv(avr_by_month, file = "/Users/macbook/Documents/Data/Project_2_Cyclist/avr_by_month.csv",row.names=FALSE)

write.csv(all_trips_v2, file = "/Users/macbook/Documents/Data/Project_2_Cyclist/all_trips_vs.csv",row.names=FALSE)

#change month from number to character for visualization
all_trips_v2$month <- case_when(all_trips_v2$month == "01" ~ "January", 
                                all_trips_v2$month == "02" ~ "February",
                                all_trips_v2$month == "03" ~ "March",
                                all_trips_v2$month == "04" ~ "April",
                                all_trips_v2$month == "05" ~ "May",
                                all_trips_v2$month == "06" ~ "June",
                                all_trips_v2$month== "07" ~ "July",
                                all_trips_v2$month == "08" ~ "August",
                                all_trips_v2$month == "09" ~ "September",
                                all_trips_v2$month == "10" ~ "October",
                                all_trips_v2$month == "11" ~ "November",
                                all_trips_v2$month == "12" ~ "December")

all_trips_v2 <- all_trips_v2 %>% 
  select(-c(bikeid,trip_id,from_station_id, to_station_id))
