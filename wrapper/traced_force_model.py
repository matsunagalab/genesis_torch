import torch
import torch.nn as nn
from typing import NamedTuple, Tuple, List, Optional

class ForceOutput(NamedTuple):
    energy: torch.Tensor
    forces: torch.Tensor

class ZForceModel(nn.Module):
    def __init__(self, force_constant=1.0):
        super(ZForceModel, self).__init__()
        # Force constant (parameter to adjust strength)
        self.force_constant = nn.Parameter(torch.tensor([force_constant]), requires_grad=False)
    
    def forward(self, coordinates):
        # coordinates: [batch_size, num_atoms, 3]
        return self.compute_energy_and_forces(coordinates)
    
    def compute_energy_and_forces(self, coordinates: torch.Tensor) -> ForceOutput:
        # Enable gradients for computation
        if not coordinates.requires_grad:
            coordinates = coordinates.detach().clone().requires_grad_(True)
        
        # Multiply constant by sum of z coordinates (generates force pulling in z direction)
        energy = self.force_constant * torch.sum(coordinates[:, :, 2])
        
        # Force calculation (negative gradient of energy)
        grads = torch.autograd.grad(
            [energy.sum()], [coordinates], 
            create_graph=True, retain_graph=True
        )
        
        # Handle the Optional[Tensor] properly
        forces_opt = grads[0]
        # Ensure forces is not None (it shouldn't be in this case)
        forces = torch.zeros_like(coordinates) if forces_opt is None else forces_opt
        # Apply the negative sign
        forces = -forces
        
        return ForceOutput(energy=energy, forces=forces)

# Create model
model = ZForceModel(force_constant=1.0)

# Convert to ScriptModule
scripted_model = torch.jit.script(model)

# Save model
scripted_model.save("traced_force_model.pt")

# add example usage
if __name__ == "__main__":
    # Create example input
    #example_input = torch.randn(1, 10, 3, requires_grad=True)
    num_atoms = 10
    example_input = torch.zeros(1, num_atoms, 3)
    for i in range(num_atoms):
        example_input[0, i, 0] = 0.1 * (i + 1)  # x coordinate
        example_input[0, i, 1] = 0.2 * (i + 1)  # y coordinate
        example_input[0, i, 2] = 0.3 * (i + 1)  # z coordinate
    example_input.requires_grad_(True)

    # Get energy and forces
    output = scripted_model(example_input)
    print(output)
