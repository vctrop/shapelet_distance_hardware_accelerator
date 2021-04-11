// Copyright GMicro UFSM 2021.
// This source describes Open Hardware and is licensed under the CERN-OHLS v2
// You may redistribute and modify this documentation and make products
// using it under the terms of the CERN-OHL-S v2 (https:/cern.ch/cern-ohl).
// This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED
// WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
// AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-S v2
// for applicable conditions.
// Source location: https://github.com/vctrop/shapelet_distance_hardware_accelerator
// As per CERN-OHL-S v2 section 4, should You produce hardware based on
// these sources, You must maintain the Source Location visible on any
// product you make using this documentation.

#include "decision_functions.h"
#include "shapelet_transform.h"

//
void matrix_vector_multiplication(uint16_t n_row, uint16_t n_col, float **in_matrix, float *in_vector, float *out_vector){
    //out_vector = safe_alloc(n_row * sizeof(*out_vector));
    
    for (uint16_t i = 0; i < n_row; i++){
        for (uint16_t j = 0; j < n_col; j++){
            out_vector[i] += in_matrix[i][j] * in_vector[j];
        }
    }
}

// // 
// void matrix_multiplication(uint16_t n_row_matA, uint16_t n_col_matA_row_matB, uint16_t n_col_matB, float **in_mat_A, float **in_mat_B, float **out_mat){
    
    // for (uint16_t i = 0; i < n_col_matA_row_matB; i++){
        // for (uint16_t j = 0; j < n_row_matA; j++){
            // for(uint16_t k = 0; k < n_col_matB; k++){
                // out_mat[n_row_matA][n_col_matB] = in_mat_A[j][i] * in_mat_B[i][k];
            // }
        // }
    // }    
// }


// Decision function of a linear classifier such as linear SVM
uint8_t *linear_decision(float **transformed_dataset, uint16_t num_ts, float *coefficient_vector, uint16_t num_shapelets){
    uint8_t *classification_result;
    float *mv_mult;
    
    classification_result   = safe_alloc (num_ts * sizeof(*classification_result));
    mv_mult                 = safe_alloc (num_ts * sizeof(*mv_mult));
    
    matrix_vector_multiplication(num_ts, num_shapelets, transformed_dataset, coefficient_vector, mv_mult);
    
    for (uint16_t i = 0; i < num_ts; i++){
        classification_result[i] = (uint8_t) (mv_mult[i] > 0);
        }
    
    return classification_result;
}

// // Sigmoid activation function
// inline float sigmoid_activation(float x){
    // return 1 / (1 + expf(-x));
// }

// // Rectified Linear Unit (ReLU) activation function
// inline float relu_activation(float x){
    // return fmaxf(0, x);
// }


// //
// // hidden_layer_activation = 's' : sigmoid function as the activation of the hidden layer
// // hidden_layer_activation = 'r' : ReLU function as the activation of the hidden layer
// //// Algebraic dimensions:
// // tabular_dataset      (n_row, n_col)
// // dataset_with_bias    (n_row, n_col + 1)
// // weights_hidden       (n_col + 1, n_hidden_nodes)
// // weights_out          (n_hidden_nodes + 1)
// uint8_t *three_layer_perceptron_decision(uint16_t n_row, uint16_t n_col, float **tabular_dataset, uint16_t n_hidden_nodes, float **weights_hidden, float *weights_out, char hidden_layer_activation){
    // float *activation(float x);
    // float **dataset_with_bias;                      // (n_row, n_col + 1)tabular_dataset with an extra column of 1s to use the first row of the weights matrix as a bias factor in the hidden ayer activations
    // float **hidden_layers_in;                       // (n_row, n_hidden_nodes)
    // float **hidden_layers_out;                      // (n_row, n_hidden_nodes + 1)
    // float *out_node_in;                             // (n_row)
    // uint8_t *tlp_predictions;                       // (n_row)
    
    // if (hidden_layer_activation != 's' and hidden_layer_activation != 'r'){
        // printf("Error, use 's'(igmoid) or 'r'(elu) as activation functions of the hidden layer\n");
        // exit(-1);
    // }
    
    
    // if (hidden_layer_activation == 's'){
        // printf("Using Sigmoid activation in the hidden layer\n");
        // activation = sigmoid_activation;
    // }
    // else{
        // printf("Using ReLU activation in the hidden layer\n");
        // activation = relu_activation;
    // }
    
    // dataset_with_bias       = safe_alloc (n_row * sizeof(*dataset_with_bias));
    // hidden_layers_in        = safe_alloc (n_row * sizeof(*hidden_layers_in));
    // hidden_layers_out       = safe_alloc (n_row * sizeof(*hidden_layers_out));
    
    
    // for (uint16_t i = 0; i < n_row; i++){
        // // Allocate inputs and outputs of the hidden nodes
        // hidden_layers_in[i] = safe_alloc (n_hidden_nodes * sizeof(**hidden_layers_in));
        // hidden_layers_out[i]= safe_alloc ((n_hidden_nodes + 1) * sizeof(**hidden_layers_out)); 
        // hidden_layers_out[i][0] = 1;            // Bias of the output node
        
        // // Bias of the hidden layer nodes
        // dataset_with_bias[i] = safe_alloc ((n_col + 1) * sizeof(**dataset_with_bias));
        // dataset_with_bias[i][0] = 1;
        // memcpy(dataset_with_bias[i]+1, tabular_dataset[i], n_col * sizeof(**tabular_dataset));        
    // }
    
    // // Bias of the output node;
    // hidden_layers_out[0] = 1;
 
    // // Compute the input of each hidden layer for each row in the dataset
    // matrix_multiplication(n_row, n_col + 1, n_hidden_nodes, dataset_with_bias, weights_hidden, hidden_layers_in);
    
    // // Compute the hidden layer's output
    // for (uint16_t i = 0; i < n_row; i++){
        // for(uint16_t j = 0; j < n_hidden_nodes; j++){
            // hidden_layers_out[i][j+1] = activation(hidden_layers_in[i][j]);
        // }
        
    // }
    
    // // Compute the input of the output node
    // out_node_in = safe_alloc (n_row * sizeof(*out_node_in));
    // matrix_vector_multiplication(n_row, n_hidden_nodes + 1, hidden_layers_out, weights_out, out_node_in);
    
    // tlp_predictions = safe_alloc (n_row * sizeof(*tlp_predictions);
    // // Compute the model's outputs
    // for (uint16_t i = 0; i < n_row, i++){
        // tlp_predictions = (uint8_t) (sigmoid_activation(out_node_in) > 0);
    // }
// }

// //
// //uint8_t multi_layer_perceptron_decision(){}