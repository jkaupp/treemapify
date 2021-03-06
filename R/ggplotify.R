#' @title Draw an exploratory treemap
#' @export
#' @family treemapify
#'
#' @description
#'
#' Takes a data frame of treemap coordinates produced by "treemapify" and draws an exploratory treemap.
#' The output is a ggplot2 plot, so it can be further manipulated e.g. a title added.
#'
#' @param treeMap a data frame of treemap coordinates produced by "treemapify"
#' @param label.groups should groups be labeled? (Individual observations will be automatically labelled if a "label" parameter was passed to "treemapify")
ggplotify <- function(treeMap, label.groups = TRUE) {

    #Libraries
    require(ggplot2)
    require(plyr)
    require(reshape2)

    #Check arguments
    if (missing(treeMap) || is.data.frame(treeMap) == FALSE) {
        stop("Must provide a data frame")
    }

    #Determine limits of plot area (usually 100x100)
    xlim <- c(min(treeMap["xmin"]), max(treeMap["xmax"]))
    ylim <- c(min(treeMap["ymin"]), max(treeMap["ymax"]))

    #Set up plot area
    Plot <- ggplot(treeMap)
    Plot <- Plot + coord_cartesian(xlim = xlim, ylim = ylim) 
    Plot <- Plot + geom_rect(aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill)) #Rects generated by treemapify
    Plot <- Plot + geom_rect(aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax), fill = NA, colour = "grey", size = 0.2) #Borders for individual rects
    Plot <- Plot + theme(axis.ticks = element_blank(), axis.title = element_blank(), axis.text=element_blank()) #Clean plot area
    Plot <- Plot + guides(fill = guide_legend(title = attributes(treeMap)$fillName)) #Legend

    #If the rects are grouped, add a nice border around each group
    if ("group" %in% colnames(treeMap)) {

        #Determine x and y extents for each group
        groupRects <- ddply(treeMap, .(group), summarise, 
            xmin <- min(xmin),
            xmax <- max(xmax),
            ymin <- min(ymin),
            ymax <- max(ymax)
        )
        names(groupRects) <- c("group", "xmin", "xmax", "ymin", "ymax")

        #Add borders to plot
        Plot <- Plot + geom_rect(data = groupRects, mapping = aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax), colour = "grey", fill = NA, size = 1.2) 
        Plot <- Plot + theme(panel.border = element_rect(size = 2, fill = NA, colour = "grey"))
    }

    #Add group labels, if asked to
    if (label.groups == TRUE && "group" %in% colnames(treeMap)) {

        #If there's a "label" column (i.e. if individual rects are
        # to be labelled), place in the top left hand corner so the
        # individual and group labels don't overlap
        if ("label" %in% colnames(treeMap)) {
            groupLabels <- ddply(treeMap, c("group"), summarise, 
                x <- max(xmax) - ((max(xmax) - min(xmin)) * 0.5),
                y <- min(ymin) + 2,
                size <- (max(xmax) - min(xmin)) / nchar(as.character(group[1]))
            )

        #Otherwise, place in the middle
        } else {
            groupLabels <- ddply(treeMap, c("group"), summarise, 
                x <- max(xmax) - ((max(xmax) - min(xmin)) * 0.5),
                y <- max(ymax) - ((max(ymax) - min(ymin)) * 0.5),
                size <- (max(xmax) - min(xmin)) / (nchar(as.character(group[1])))
            )
        }
        names(groupLabels) <- c("group", "x", "y", "size")
        Plot <- Plot + annotate("text", x = groupLabels$x, y = groupLabels$y, label = groupLabels$group, size = groupLabels$size, colour = "darkgrey", fontface = "bold", hjust = 0.5, vjust = 0)
    }

    #Add labels for individual rects, if they are present
    if ("label" %in% colnames(treeMap)) {

        #Determine label size and placement
        treeMap <- ddply(treeMap, "label", mutate,

            #Place in top left
            labelx = xmin + 1,
            labely = ymax - 1,
            labelsize = (xmax - xmin) / (nchar(as.character(label))), #Rough scaling of label size
        )

        #Add labels
        Plot <- Plot + geom_text(data = treeMap, aes(label = label, x = labelx, y = labely, size = labelsize), hjust = 0, vjust = 1, colour = "white") + scale_size(range = c(1,8), guide = FALSE)
    }

    return(Plot)
}
