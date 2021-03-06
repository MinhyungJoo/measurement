library(reshape)
library(rstan) # load rstan library
set_cppo("fast")  # for best running speed


# set time start variable
time1 <- Sys.time()
print(Sys.time() - time1)


# -------------------------------------------------- #
# define STAN model
# -------------------------------------------------- #
model <- "
data {
    int<lower=0> N;
    int<lower=0> K;
    int<lower=0> N_K;
    int<lower=1> n[N_K];
    int<lower=0, upper=1> y[N_K];
    int<lower=0, upper=K> item[N_K];
}

parameters {
    real alpha[K];
    real<lower=0> beta[K];
    real x[N];
}

transformed parameters {
    real eta[N_K];
    
    for(i in 1:N_K){
        eta[i] <- alpha[item[i]] + beta[item[i]] * x[n[i]];
    }
}

model {
    x ~ normal(0,1); //priors on latent variable
    alpha ~ normal(0,10); //priors (these are variances not precision)
    beta ~ gamma(4,3);
    
    y ~ bernoulli_logit(eta);
}
"
# -------------------------------------------------- #

N <- 100
x <- rnorm(N,0,1)

alpha1 <- -1.000000
alpha2 <- 0.000000
alpha3 <- 1.000000
beta1 <- 1.000000
beta2 <- 2.000000
beta3 <- 3.000000

# define k as the number of items
#K <- 3 # define it below now

# linear terms of the model
xb1 <- alpha1 + beta1 * x
xb2 <- alpha2 + beta2 * x
xb3 <- alpha3 + beta3 * x

# transform the linear xb terms using the logit function
# so that theta is bound from 0 to 1
theta1 <- 1 / (1 + exp(-xb1))
theta2 <- 1 / (1 + exp(-xb2))
theta3 <- 1 / (1 + exp(-xb3))

# generate the items with theta and measurment error
y1 <- rbinom(N, size=1, prob=theta1)
y2 <- rbinom(N, size=1, prob=theta2)
y3 <- rbinom(N, size=1, prob=theta3)
y <- cbind(y1, y2, y3)

temp <- melt(y)
item <- as.numeric(temp$X2)
y <- temp$value
K <- max(item)
N_K <- nrow(temp)
n <- as.numeric(temp$X1)

# create data list
data <- list(y=y, item=item, K=K, N=N, N_K=N_K)


# fit stan model
fit <- stan(model_code = model, data = data, iter = 100, chains = 1)


# this summarizes the named parameters but not along the dimensions
fit

# extract draws from stan model object
output <- extract(fit, permuted = TRUE)

# print names
names(output)


# this prints the posterior mean for the latent variable
apply(output$x,2,mean)

# plot true latent variable with posterior mean
par(mar=c(4,4,1,1), font=2, font.lab=2, cex=1.3)
plot(apply(output$x,2,mean), x, xlim=c(-3,3), ylim=c(-3,3), ylab="true x", xlab="posterior mean of x")
abline(a=0, b=1, col=2, lwd=2)


print(Sys.time() - time1)
