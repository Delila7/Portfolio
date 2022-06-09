#tutorial from Python Engineer @ https://www.youtube.com/watch?v=Klqn--Mu2pE&t=87s

import streamlit as st
from sklearn import datasets
import numpy as np
from sklearn.neighbors import KNeighborsClassifier
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
from sklearn.decomposition import PCA
import numpy as np
import matplotlib.pyplot as plt

st.title('Streamlit example')

#Write Text with Markdown Formatting
st.write("""
# Explore different classifier
Which one is the best?
""")

#add widgets
dataset_name = st.sidebar.selectbox('Select Dataset', ('Iris', 'Breast Cancer', 'Wine dataset'))

classifier_name = st.sidebar.selectbox('Select Classifier', ('KNN', 'SVM', 'RandomForest'))

#load datasets
def get_dataset(dataset_name):
    if dataset_name == 'Iris': 
        data = datasets.load_iris()
    elif dataset_name == 'Breast Cancer':
        data = datasets.load_breast_cancer()
    else:
        data = datasets.load_wine()
    X = data.data
    y = data.target
    return X, y

X,y = get_dataset(dataset_name)
st.write('shape of dataset', X.shape)
st.write('number of classes', len(np.unique(y)))

#get widgets to modify parameters for each of the classifiers
# check sklearn documentation to add additional parameters for each classifier
def add_parameter_ui(clf_name):
    params = dict()
    if clf_name == 'KNN':
        K = st.sidebar.slider('K', 1, 15)
        params['K'] = K
    elif clf_name == 'SVM':
        C = K = st.sidebar.slider('C', .01, 10.0)
        params['C'] = C
    else: 
        max_depth = st.sidebar.slider('max_depth', 2, 15)
        n_estimators = st.sidebar.slider('n_estimators', 1, 100)
        params['max_depth']= max_depth
        params['n_estimators'] = n_estimators
    return params

params = add_parameter_ui(classifier_name)

#create classifiers
def get_classifier(clf_name, params):
    if clf_name == 'KNN':
        clf = KNeighborsClassifier(n_neighbors = params['K'])
    elif clf_name == 'SVM':
        clf = SVC(C = params['C'])
    else: 
        clf = RandomForestClassifier(n_estimators = params['n_estimators'],
                                    max_depth = params['max_depth'], random_state = 1234)   
    return clf

clf = get_classifier(classifier_name, params)

#split data, train classifier
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 0.2, random_state=1234)

clf.fit(X_train, y_train) #API is same for all classifiers in sklearn library
y_pred = clf.predict(X_test)

acc= accuracy_score(y_test, y_pred)
st.write(f'classifier = {classifier_name}')
st.write(f'accuracy = {acc}')

#plot (We have more than two variables for some datasets, but must plot in 2D)
pca = PCA(2)
X_projected = pca.fit_transform(X) #unsupervised dimensionality reduction technique

x1 = X_projected[:, 0]
x2 = X_projected[:, 1]

fig, ax = plt.subplots()
plt.scatter(x1, x2, c = y, alpha = 0.8, cmap = 'viridis')
plt.xlabel('Principal Component 1')
plt.xlabel('Principal Component 2')
plt.colorbar()

st.pyplot(fig) #plt.show()

# To Do
#add more parameters (sklearn)
#add other classifiers
#add feature scaling

#See also youtube.com/watch?v=xl0N7tHiwlw