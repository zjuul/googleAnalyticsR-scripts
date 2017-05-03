# dynamic segmenting demo

# this queries a top-ten viewed pages, and uses the pagename to
# make a dynamic segment of people who viewed the page, then made a transaction
# so, in effect, measure the conversion rate of a page.


library(googleAnalyticsR)
ga_auth()
viewId <- 42660662 # change this to your view

topten_pages <- google_analytics_4(viewId, date_range = c("28daysAgo", "yesterday"),
                                   dimensions = "pagePath", metrics = "uniquePageviews",
                                   order = order_type("uniquePageviews", sort_order = "DESCENDING"),
                                   max = 10)

topten_pages$transactions <- apply(topten_pages, 1, function(row) {
    p <- row["pagePath"]
    
    # create a sequenced segment: 1st step: page seen. 2nd one: >0 transactions
    s1 <- segment_element("pagePath", scope = "SESSION",
                         operator = "EXACT", 
                         type = "DIMENSION", 
                         expressions = p)
  
    s2 <- segment_element("transactions", scope = "SESSION",
                         operator = "GREATER_THAN",
                         type = "METRIC",
                         comparisonValue = 0)
    
    # glue them together
    sv_sequence <- segment_vector_sequence(list(list(s1), 
                                              list(s2)))

    # use in a query, return the transaction 
    google_analytics_4(viewId, date_range = c("28daysAgo", "yesterday"),
                       metrics = "transactions",
                       segments = segment_ga4("sequence", user_segment = segment_define(list(sv_sequence)))
                      )[["transactions"]]
  }
)

topten_pages$cr <- topten_pages$transactions / topten_pages$uniquePageviews

# output on screen
topten_pages
