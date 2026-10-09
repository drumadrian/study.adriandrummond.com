Machine Learning & AI Terminology Cheat Sheet
# Machine Learning & AI Terminology Cheat Sheet

**Total Terms Defined:** 41

---

### 1. Types of Regularization (7 terms)
*Techniques used to penalize the model to prevent overfitting and improve generalization.*
1.  **L1 Regularization (Lasso):** Adds an absolute value penalty to weights, forcing less important feature weights to exactly zero (feature selection).
2.  **L2 Regularization (Ridge):** Adds a squared penalty to weights, shrinking them evenly to prevent any single feature from dominating.
3.  **Elastic Net:** A hybrid combination of L1 and L2 regularization.
4.  **Dropout:** Randomly deactivating a percentage of neurons in a network during training to prevent them from co-adapting too closely.
 https://docs.pytorch.org/docs/2.14/generated/torch.nn.Dropout.html
5.  **Early Stopping:** Stopping the training process the moment the model's performance on a validation dataset starts getting worse.
6.  **Data Augmentation:** Artificially increasing the size of the training set by applying random transformations (flips, rotations) to the input data.
7.  **Batch Normalization:** Normalizing the inputs of each layer to stabilize and accelerate training (acts as a mild regularizer).

---

### 2. Types of Optimizations / Optimizers (8 terms)
*Algorithms used to update the model's weights to minimize the cost/loss function.*
1.  **Gradient Descent (GD):** The foundational algorithm; calculates the error of the entire dataset before taking one step to adjust the weights.
2.  **Stochastic Gradient Descent (SGD):** Calculates the error and updates weights after *every single* data point. Fast but erratic.
3.  **Mini-Batch SGD:** The industry standard; calculates error and updates weights after a small batch of data (e.g., 32 or 64 samples).
4.  **Momentum:** An addition to SGD that remembers the direction of previous weight updates, helping it push through "flat" areas of the math and avoid getting stuck.
5.  **AdaGrad:** Adapts the learning rate for each individual weight. Good for sparse data.
6.  **RMSprop:** Fixes AdaGrad's tendency to shrink the learning rate too fast by using a moving average of recent gradients.
7.  **Adam (Adaptive Moment Estimation):** The most popular modern optimizer. It combines the benefits of Momentum (remembering past directions) and RMSprop (adapting learning rates for each weight).
8.  **Polyak Averaging (EMA Weight Averaging):** Stabilizes model parameters by maintaining a separate "shadow" set of weights that are an exponential moving average of all past weights from the optimizer.

---

### 3. Meta-Algorithms / Ensembles (6 terms)
*Techniques that combine multiple "weak" models into one "strong" super-model.*
1.  **Ensemble Learning:** The general concept of combining multiple models to improve accuracy and robustness.
2.  **Bagging (Bootstrap Aggregating):** Training multiple independent models in parallel on random subsets of the data, then averaging their predictions (e.g., Random Forest).
3.  **Boosting:** Training models *sequentially*. Each new model specifically focuses on fixing the mistakes made by the previous model (e.g., Gradient Boosting).
4.  **Stacking:** Training multiple different types of models (e.g., a tree, a neural net, a regression model) and using another meta-model to learn how to best combine their outputs.
5.  **Random Forest:** A specific type of Bagging that combines hundreds of Decision Trees.
6.  **XGBoost / LightGBM:** Highly optimized, lightning-fast industry implementations of Gradient Boosting.

---

### 4. Core Concepts (7 terms)
1.  **Overfitting:** When a model memorizes the training data perfectly but fails completely on new, unseen data.
2.  **Underfitting:** When a model is too simple to capture the patterns in the data; performs poorly on both training and testing data.
3.  **Bias-Variance Tradeoff:** The balancing act between a model making overly simple assumptions (High Bias = Underfitting) and being overly sensitive to noise (High Variance = Overfitting).
4.  **Epoch:** One complete pass of the *entire* training dataset through the algorithm.
5.  **Batch Size:** The number of training examples processed before the model updates its weights.
6.  **Learning Rate:** The "step size" the optimizer takes when adjusting weights. Too high = model overshoots the answer. Too low = model takes forever to train.
7.  **Hyperparameter:** Settings you configure *before* training starts (like learning rate, batch size, number of layers). Distinct from *parameters* (weights), which the model learns on its own.

---

### 5. Types of Learning (4 terms)
1.  **Supervised Learning:** Training on data that has labeled answers (e.g., classifying images as "cat" or "dog").
2.  **Unsupervised Learning:** Training on data with no labels. The model must find hidden structures on its own (e.g., clustering customers into segments).
3.  **Semi-Supervised Learning:** Using a tiny amount of labeled data to help the model learn from a massive amount of unlabeled data.
4.  **Reinforcement Learning:** An agent learns to make decisions by performing actions in an environment and receiving rewards or punishments (e.g., an AI learning to play chess).

---

### 6. Loss Functions (4 terms)
*Mathematical formulas that calculate exactly how "wrong" the model's current predictions are.*
1.  **Mean Squared Error (MSE):** The standard loss function for **Regression** (predicting continuous numbers). Penalizes large errors heavily.
2.  **Cross-Entropy Loss (Log Loss):** The standard loss function for **Classification** (predicting categories). 
3.  **Mean Absolute Error (MAE):** Similar to MSE, but doesn't square the error. Less sensitive to massive outliers.
4.  **Hinge Loss:** Used specifically for Support Vector Machines (SVMs).

---

### 7. Activation Functions (5 terms)
*Functions that introduce non-linearity into a neural network.*
1.  **Sigmoid:** Squashes outputs to a range between 0 and 1. Historically used, but suffers from the "vanishing gradient" problem.
2.  **Tanh:** Squashes outputs to a range between -1 and 1. Better than Sigmoid as it is zero-centered.
3.  **ReLU (Rectified Linear Unit):** If the input is negative, output 0. If positive, output the input. The default standard for modern hidden layers.
4.  **Leaky ReLU:** A variation of ReLU that allows a tiny, non-zero gradient when the input is negative, preventing "dead" neurons.
5.  **Softmax:** Used exclusively on the *final* output layer of a multi-class classification network. It turns raw model outputs into a set of probabilities that add up to 1.0 (100%).

---

## ðŸš€ How Gradient Boosting Works (Simple Explanation)

Imagine you are playing golf, trying to hit the ball into the hole. 

1.  **Model 1 (The First Swing):** You take your first shot. It gets you reasonably close, but you miss the hole by 10 feet to the right. 
2.  **Model 2 (The Correction):** Now, you build a *second* model. But this second model doesn't care about the tee or the fairway. Its **only job** is to figure out how to hit a ball exactly 10 feet to the left to fix the error of the first swing. It swings, but overcompensates slightly, missing by 2 feet to the left.
3.  **Model 3 (The Micro-Correction):** You build a third model whose sole purpose is to fix that 2-foot error.

**Gradient Boosting** works exactly like this. Instead of building one massive model, it builds a sequence of small, weak models (usually shallow decision trees). 
*   Tree 1 makes a prediction.
*   Tree 2 looks at the *errors* (residuals) of Tree 1 and tries to predict and fix them.
*   Tree 3 looks at the remaining *errors* of Tree 2 and tries to fix them.

It combines all these sequential corrections together into one incredibly accurate final prediction.










---

### 8. Loss Landscape Challenges (2 terms)
*Obstacles that optimizers face when trying to navigate the loss function to find the lowest error.*
1.  **Saddle Points:** Points where the gradient is exactly zero (it looks flat), but they aren't actual minimums. (It curves up in one direction and down in another, like a horse's saddle). A basic optimizer might get stuck here, thinking it found the bottom.
2.  **Cliffs:** Sudden, steep drops in the loss function. These create extremely large ("exploding") gradients that can violently change the weights too much, throwing the model entirely off track.

*Note: Advanced optimizers (like Adam or Momentum) and techniques (like gradient clipping) are specifically designed to keep the loss function in a state where weights can be safely updated. Without them, the model will get stuck in a saddle point or jump off a cliff and not be able to recover.*














---

### 9. Data Preprocessing & Architecture
1. **Mean Imputation:** A technique for handling missing data by replacing blank or null values with the mathematical average (mean) of that feature's column.
2. **Fully Connected / Dense Layer:** A network layer where *every* neuron is connected to *every* neuron in the subsequent layer. This is the standard layer type in basic neural networks.

### 10. Training Mechanisms: Gradient Descent vs Backprop
*To answer your notes: these two concepts work together, but do different jobs!*
1. **Backpropagation:** The math process of *calculating the error* (the gradients). It works backwards from the output layer down to the input layer, figuring out exactly how much each weight in the network contributed to the final mistake.
2. **Gradient Descent:** The optimization process of *using that calculated error* to actually update and adjust the weights. 
*(Note: Simple Linear Regression doesn't have multiple hidden layers, so you just calculate the error and use Gradient Descent directly. Backpropagation is a term used specifically for calculating error backward through multiple layers of a Deep Neural Network).*











---

### 11. Network Architecture Scenarios
1. **Multi-Class Output (Softmax):** If you are classifying an image as *either* a cat, dog, or bird (only one can win), your final layer has 3 nodes. You apply Softmax, which forces the 3 probabilities to add up to 100%.
2. **Multi-Label / Time-Window Output (Sigmoid):** If you are predicting the probability of rain for the next 24 hours (1-hour increments), your output layer has 24 nodes. Because it can rain at 1 PM *and* 2 PM (they are independent), you apply **Sigmoid** to all 24 nodes so each node outputs its own independent 0-100% probability.
3. **Input Layer Biases:** The input layer does not have biases or activation functions. It simply holds the raw input data. Biases and activation functions only exist on the *hidden* and *output* layers.

### 12. Mathematical Foundations
1. **Normal vs. Partial Derivatives:** In simple linear regression, you can use normal derivatives to find the gradient. However, Neural Networks are massive chains of nested functions (layer inside a layer inside a layer). To find the gradient of a weight deep inside the network, you **must** use the Chain Rule, which requires taking **Partial Derivatives** (calculating the derivative with respect to one specific weight while holding the other million weights perfectly constant).
2. **Ordinary Differential Equations (ODEs):** Equations involving derivatives with respect to only **one** independent variable (e.g., calculating changes over *Time*).
3. **Partial Differential Equations (PDEs):** Equations involving derivatives with respect to **multiple** independent variables (e.g., calculating changes over *Time* AND *3D Space*, like fluid dynamics or heat dispersion).




In Adrian's words (subject to future enhancement)
partial differential equations vs normal differential equations

I think it's taking the derivative of a function with 2 independant values with respect to only 1 of the 2 variables...or more other variables

for ordinary, it's the differential or 1 variable to show how it changes as the other independant varible changes (a function with 1 input)


**Ordinary Differential Equations (ODEs)**
Ordinary differentiation operates on single-variable functions, where the output depends on exactly one independent variable. It represents the infinitesimal change of the function relative to that single variable, using the standard $d$ notation. For example, given a function $y = f(x) = x^3 + 4x$, the ordinary derivative is $\frac{dy}{dx} = 3x^2 + 4$. An Ordinary Differential Equation (ODE) is simply an equation that contains these types of single-variable derivatives.

**Partial Differential Equations (PDEs)**
Partial differentiation operates on multi-variable functions, where the output depends on two or more independent variables. Because the function can change in multiple directions, you take the derivative with respect to just *one* variable at a time, strictly treating all other variables as constants. This is denoted by the $\partial$ (del) symbol. For example, given the function $f(x, y) = x^2y + \sin(x)$:

* Differentiating with respect to $x$ (treating $y$ as a constant) yields $\frac{\partial f}{\partial x} = 2xy + \cos(x)$.

* Differentiating with respect to $y$ (treating $x$ as a constant) yields $\frac{\partial f}{\partial y} = x^2$.

A Partial Differential Equation (PDE) is an equation that includes these multi-variable partial derivatives.





also, 

define: Polyak Averaging

    Polyak Averaging, also known as Exponential Moving Average (EMA) Weight Averaging, is a technique used to stabilize the model parameters during training, particularly in deep learning.
    
    In essence, instead of using the raw, often noisy weights from the last training step, Polyak Averaging maintains a separate "shadow" set of weights that are a moving average of all past weights.

    Mathematical Explanation:
    Let Î¸t be the model weights at training step t.
    Let Î¸EMA_t be the exponential moving average (the "shadow" weights) at step t.

    The update rule is defined as:

    Î¸EMA_t = (1 - Î±) * Î¸EMA_{t-1} + Î± * Î¸t

    Where:
    Î¸EMA_{t-1} is the previous average weight.
    Î¸t is the current "live" weight (from the optimizer).
    Î± (alpha) is the smoothing factor (typically a small number like 0.001 or 0.0001).

    

















# Machine Learning Algorithms by Lifecycle Phase

| Phase | Category | Specific Algorithms / Techniques | Meta-Algorithm / Type | Primary Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **1: Pre-processing** | Dimensionality Reduction | PCA, t-SNE, UMAP, LDA | Unsupervised Learning | Reduce feature space while retaining variance/structure. |
| **1: Pre-processing** | Data Scaling & Transformation | StandardScaler, MinMaxScaler, Log Transform | Data Transformation | Normalize data ranges for distance-based or gradient-based algorithms. |
| **1: Pre-processing** | Imbalanced Data Handling | SMOTE, ADASYN, Undersampling | Oversampling/Resampling | Balance class distributions for classification tasks. |
| **1: Pre-processing** | Feature Extraction / Encoding | Word2Vec, TF-IDF, Autoencoders, One-Hot Encoding | Representation Learning | Convert raw text/images/categories into numerical vectors. |
| **2: Processing/Training** | Core Learning Algorithms | Linear Regression, SVM, Decision Trees, Neural Networks | Supervised / Unsupervised | Learn the underlying patterns mapping inputs to outputs. |
| **2: Processing/Training** | Optimizers (Weight Updates) | Gradient Descent (Batch), SGD, Mini-Batch GD, Adam, RMSProp, Momentum | Optimization Algorithms | Find the local/global minimum of the loss function efficiently. |
| **2: Processing/Training** | Ensembling Techniques | Random Forest, XGBoost, AdaBoost, LightGBM | Bagging / Boosting | Combine multiple weak learners into a strong learner to reduce variance or bias. |
| **2: Processing/Training** | Regularization (In-Training) | L1 (Lasso), L2 (Ridge), Dropout, Polyak Averaging, Batch Normalization | Regularization | Prevent overfitting by penalizing complexity or adding noise during training. |
| **3: Validation** | Hyperparameter Tuning | Grid Search, Random Search, Bayesian Optimization (e.g., Hyperopt) | Search / Optimization | Find the best architectural settings (learning rate, depth, etc.) before final testing. |
| **3: Validation** | Resampling / Splitting | K-Fold Cross Validation, Stratified K-Fold, Leave-One-Out | Evaluation Methodology | Ensure the model's performance metrics are robust and not dependent on a lucky split. |
| **3: Validation** | Stopping Criteria | Early Stopping | Regularization Meta-Algorithm | Halt training when performance on the validation set stops improving. |
| **4: Testing** | Performance Evaluation | ROC-AUC, F1-Score, RMSE, Confusion Matrix | Evaluation Metrics | Quantify the final, unbiased performance of the model on completely unseen data. |
| **4: Testing** | Explainability / Interpretability | SHAP (SHapley Additive exPlanations), LIME | XAI (Explainable AI) | Understand feature importance and why the model makes specific predictions. |
| **5: Production (Runtime)** | Model Compression | Quantization (e.g., FP32 to INT8), Weight Pruning | Optimization / Deployment | Reduce model size and latency for faster inference on edge devices or servers. |
| **5: Production (Runtime)** | Continuous Learning | Online Learning (e.g., Vowpal Wabbit), Federated Learning | Meta-Learning Strategy | Update the model incrementally in real-time as new data arrives without full retraining. |
| **5: Production (Runtime)** | Live Evaluation / Routing | Multi-Armed Bandits, A/B Testing | Reinforcement Learning / Stats | Dynamically route traffic to the best performing model in a live environment. |
| **5: Production (Runtime)** | Model Serving | Knowledge Distillation, ONNX Runtime, TensorRT | Engineering / Serving | Deploy models efficiently; Distillation trains a fast "student" model from a large "teacher". |
