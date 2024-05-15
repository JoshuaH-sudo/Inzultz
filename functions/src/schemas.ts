import Joi = require("joi");

export const updateContactRequestSchema = Joi.object({
  contactRequestId: Joi.string().required(),
  newStatus: Joi.string().valid("accepted", "declined").required(),
});
