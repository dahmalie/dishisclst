library(tidyverse)  # dplyr, ggplot, etc.
library(ggforce)  # sankey plots

clusterings <- read_tsv(snakemake@input[[1]], col_types = cols())

# clustering granularity levels
ip_vals <- as.character(unique(clusterings$ip))

# overall cluster flows
flows <- clusterings %>% 
    mutate_at("cluster", ~ fct_relevel(fct_infreq(.x), "rest", after=Inf)) %>% 
    pivot_wider(names_from = ip, values_from = cluster) %>% 
    group_by_at(vars(-pid)) %>% 
    tally(name = "n_patients") %>% 
    ungroup()

# set theme and layout params
theme_set(theme_no_axes())
theme_update(legend.position = "none")
sank_sep <- 1/200

# female cluster flows
plot <- flows %>% 
    mutate(fill = .data[[tail(ip_vals, 1)]]) %>% 
    gather_set_data(ip_vals) %>% 
    ggplot(aes(x = x, id = id, split = y, value = n_patients)) +
    geom_parallel_sets(aes(fill = fill), axis.width = 1/10, sep = sank_sep) +
    geom_parallel_sets_axes(axis.width = 1/10, sep = sank_sep) +
    geom_parallel_sets_labels(
        color = "white", sep = sank_sep,  size = 2, angle = 0
    ) +
    scale_fill_hue(h = c(0, 360) + 15, c = 100, l = 65) +
    labs(caption = str_c(c(snakemake@wildcards[1:4]), collapse = ", "))

ggsave(
    snakemake@output[[1]], plot = plot, scale = 2.5,
    width = 10, height = 5, unit = "cm"
)
