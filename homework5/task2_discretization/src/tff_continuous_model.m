function model = tff_continuous_model()
%TFF_CONTINUOUS_MODEL Return the required transfer function and state model.
model.A = [0 1; -33.33 -1];
model.B = [0; 1];
model.C = [0.3333 0];
model.D = 0;
model.sys = ss(model.A, model.B, model.C, model.D);
model.tf = tf([0.3333], [1 1 33.33]);
end
