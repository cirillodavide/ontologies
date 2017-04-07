import tensorflow as tf
import numpy as np

# embedding matrix
embeddings = tf.Variable(
    tf.random_uniform([vocabulary_size, embedding_size], -1.0, 1.0))

# noise-contrastive estimation (NCE) loss parameters
nce_weights = tf.Variable(
  tf.truncated_normal([vocabulary_size, embedding_size],
                      stddev=1.0 / math.sqrt(embedding_size)))
nce_biases = tf.Variable(tf.zeros([vocabulary_size]))

# placeholders for inputs
train_inputs = tf.placeholder(tf.int32, shape=[batch_size])
train_labels = tf.placeholder(tf.int32, shape=[batch_size, 1])

# embeddings for each word
embed = tf.nn.embedding_lookup(embeddings, train_inputs)

# compute the NCE loss (the training objective)
loss = tf.reduce_mean(
  tf.nn.nce_loss(nce_weights, nce_biases, embed, train_labels,
                 num_sampled, vocabulary_size))

# compute the gradients, update the parameters, etc.
optimizer = tf.train.GradientDescentOptimizer(learning_rate=1.0).minimize(loss)

# training the model
for inputs, labels in generate_batch(...):
  feed_dict = {training_inputs: inputs, training_labels: labels}
  _, cur_loss = session.run([optimizer, loss], feed_dict=feed_dict)
